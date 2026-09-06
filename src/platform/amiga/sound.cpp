#include "common.h"

#include <devices/audio.h>
#include <hardware/custom.h>
#include <hardware/intbits.h>
#include <hardware/dmabits.h>
#include <hardware/cia.h>
#include <graphics/gfxbase.h>
#include <proto/graphics.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <SDI_interrupt.h>

static struct CIA *ciaa = (struct CIA *)0xbfe001;
static struct Custom *custom = (struct Custom *)0xdff000;

static struct Interrupt *oldIntAud0 = NULL;
static struct Interrupt *oldIntAud2 = NULL;
static struct MsgPort *audioMP = NULL;
static struct IOAudio *audioIO = NULL;
static BYTE audioDev = -1;
static UBYTE oldFilter = 0;
static struct Interrupt AudioInt;

uint8 ADPCM4_ADAPT[] = { // IWRAM !
    192,192,136,136,128,128,128,128, // -8..-1
    112,128,128,128,128,136,136,192, //  0..+7
};

int8 soundBuffer[2 * SND_SAMPLES] __attribute((__chip__));
int8 musicBuffer[2 * SND_SAMPLES] __attribute((__chip__));

#ifdef USE_ASM
    #define sndADPCM4_fill sndADPCM4_fill_asm
    #define sndPCM_fill    sndPCM_fill_asm
    #define sndPCM_mix     sndPCM_mix_asm

    extern "C" {
        void sndADPCM4_fill_asm(ADPCM4_STATE &state __asm("a0"), int8* buffer __asm("a1"), const uint8* data __asm("a2"), int32 size __asm("d0"));
        int32 sndPCM_fill_asm(int32 pos __asm("d0"), int32 inc __asm("d1"), int32 size __asm("d2"), int32 volume __asm("d3"), const uint8* data __asm("a0"), int8* buffer __asm("a1"));
        int32 sndPCM_mix_asm(int32 pos __asm("d0"), int32 inc __asm("d1"), int32 size __asm("d2"), int32 volume __asm("d3"), const uint8* data __asm("a0"), int8* buffer __asm("a1"));
    }
#else
    #define sndADPCM4_fill sndADPCM4_c
    #define sndPCM_fill    sndPCM_fill_c
    #define sndPCM_mix     sndPCM_mix_c

#define DECODE_ADPCM4(n)\
    tap = zM2 + tap - (tap >> 3);\
    *buffer++ = SND_ENCODE(X_CLAMP(tap >> 8, SND_MIN, SND_MAX));\
    res = ((n&0xF) ^ 8) - 8;\
    out = res*quant + (zM1 - zM2);\
    zM2 = zM1;\
    zM1 = out;\
    quant = (quant*(int32)ADPCM4_ADAPT[res+8] + 127) >> 7;\

void sndADPCM4_c(ADPCM4_STATE &state, int8* buffer, const uint8* data, int32 size)
{
    int32 zM1   = state.zM1;
    int32 zM2   = state.zM2;
    int32 tap   = state.tap;
    int32 quant = state.quant;
    int32 res, out;
    
    for (int32 i=0; i < size; i++)
    {
        uint32 n = *data++;
        DECODE_ADPCM4(n);
        n >>= 4;
        DECODE_ADPCM4(n);
    }
    
    state.zM1   = zM1;
    state.zM2   = zM2;
    state.tap   = tap;
    state.quant = quant;
}

int32 sndPCM_fill_c(int32 pos, int32 inc, int32 size, int32 volume, const uint8* data, int8* buffer)
{
    int32 last = pos + SND_SAMPLES * inc;
    if (last > size) {
        last = size;
    }

    if (volume == (1 << SND_VOL_SHIFT))
    {
        while (pos < last)
        {
            *buffer++ = SND_DECODE(data[pos >> SND_FIXED_SHIFT]);
            pos += inc;
        }
    }
    else
    {
        while (pos < last)
        {
            *buffer++ = ((SND_DECODE(data[pos >> SND_FIXED_SHIFT]) * volume) >> SND_VOL_SHIFT);
            pos += inc;
        }
    }

    return pos;
}

int32 sndPCM_mix_c(int32 pos, int32 inc, int32 size, int32 volume, const uint8* data, int8* buffer)
{
    int32 last = pos + SND_SAMPLES * inc;
    if (last > size) {
        last = size;
    }

    if (volume == (1 << SND_VOL_SHIFT))
    {
        while (pos < last)
        {
            int16 amp = *buffer + SND_DECODE(data[pos >> SND_FIXED_SHIFT]);
            *buffer++ = X_CLAMP(amp, SND_MIN, SND_MAX);
            pos += inc;
        }
    }
    else
    {
        while (pos < last)
        {
            int16 amp = *buffer + ((SND_DECODE(data[pos >> SND_FIXED_SHIFT]) * volume) >> SND_VOL_SHIFT);
            *buffer++ = X_CLAMP(amp, SND_MIN, SND_MAX);
            pos += inc;
        }
    }

    return pos;
}

#endif

struct Music
{
    const uint8*  data;
    int32         size;
    int32         pos;
    ADPCM4_STATE  state;

    void fill(int8* buffer)
    {
        int32 len = X_MIN(size - pos, SND_SAMPLES >> 1);

        sndADPCM4_fill(state, buffer, data + pos, len);

        pos += len;

        if (pos >= size)
        {
            data = NULL;
            memset(buffer + (len << 1), 0, (SND_SAMPLES - (len << 1)) * sizeof(buffer[0]));
        }
    }
};

struct Sample
{
    int32        pos;
    int32        inc;
    int32        size;
    int32        volume;
    const uint8* data;

    void mix(int8* buffer)
    {
        pos = sndPCM_mix(pos, inc, size, volume, data, buffer);

        if (pos >= size)
        {
            data = NULL;
        }
    }

    void fill(int8* buffer)
    {
        pos = sndPCM_fill(pos, inc, size, volume, data, buffer);

        if (pos >= size)
        {
            data = NULL;
        }
    }
};

static Music  music;
static Sample channels[SND_CHANNELS];
static int32  channelsCount;
static uint32 curSoundBuffer = 0;
static uint32 curMusicBuffer = 0;

#define CALC_INC (((SND_SAMPLE_FREQ << SND_FIXED_SHIFT) / SND_OUTPUT_FREQ) * pitch >> SND_PITCH_SHIFT)

INTERRUPTPROTO(AudioFunc, ULONG, struct Custom *c, APTR data)
{
    UWORD intreqr = c->intreqr;

    if (intreqr & INTF_AUD0) { // SFX
        curSoundBuffer ^= SND_SAMPLES;
        int8 *buffer = soundBuffer + curSoundBuffer;

        c->aud[0].ac_ptr = (UWORD *)buffer;
        c->aud[1].ac_ptr = (UWORD *)buffer;
        sndFill(buffer);
        c->intreq = INTF_AUD0;
    }

    if (intreqr & INTF_AUD2) { // Music
        curMusicBuffer ^= SND_SAMPLES;
        int8 *buffer = musicBuffer + curMusicBuffer;

        c->aud[2].ac_ptr = (UWORD *)buffer;
        c->aud[3].ac_ptr = (UWORD *)buffer;
        if (music.data)
        {
            music.fill(buffer);
        }
        c->intreq = INTF_AUD2;
    }

    return 0;
}

void sndFree()
{
    struct Interrupt *restoreAud0 = NULL;
    struct Interrupt *restoreAud2 = NULL;

    if (oldFilter) {
        ciaa->ciapra |= oldFilter;
        oldFilter = 0;
    }

    if (oldIntAud0) {
        custom->dmacon = DMAF_AUD0|DMAF_AUD1;
        custom->intena = INTF_AUD0;
        custom->intreq = INTF_AUD0;
        restoreAud0 = oldIntAud0;
        oldIntAud0 = NULL;
    }

    if (oldIntAud2) {
        custom->dmacon = DMAF_AUD2|DMAF_AUD3;
        custom->intena = INTF_AUD2;
        custom->intreq = INTF_AUD2;
        restoreAud2 = oldIntAud2;
        oldIntAud2 = NULL;
    }

    if (!audioDev) {
        CloseDevice((struct IORequest *)audioIO);
        audioDev = -1;
    }

    if (restoreAud0)
        SetIntVector(INTB_AUD0, restoreAud0);

    if (restoreAud2)
        SetIntVector(INTB_AUD2, restoreAud2);

    if (audioIO) {
        DeleteIORequest((struct IORequest *)audioIO);
        audioIO = NULL;
    }

    if (audioMP) {
        DeleteMsgPort(audioMP);
        audioMP = NULL;
    }
}

void sndInit()
{
    if ((audioMP = CreateMsgPort())) {
        if ((audioIO = (struct IOAudio *)CreateIORequest(audioMP, sizeof(struct IOAudio)))) {
            UBYTE whichannel[] = {15};

            audioIO->ioa_Request.io_Message.mn_Node.ln_Pri = 127;
            audioIO->ioa_Request.io_Command = ADCMD_ALLOCATE;
            audioIO->ioa_Request.io_Flags = ADIOF_NOWAIT;
            audioIO->ioa_AllocKey = 0;
            audioIO->ioa_Data = whichannel;
            audioIO->ioa_Length = sizeof(whichannel);

            if (!(audioDev = OpenDevice((STRPTR)AUDIONAME, 0, (struct IORequest *)audioIO, 0))) {
                UWORD period;
                if (GfxBase->DisplayFlags & PAL) {
                    period = 3546895 / SND_OUTPUT_FREQ;
                } else {
                    period = 3579545 / SND_OUTPUT_FREQ;
                }

                AudioInt.is_Node.ln_Type = NT_INTERRUPT;
                AudioInt.is_Node.ln_Pri = 100;
                AudioInt.is_Node.ln_Name = (char *)"OpenLara Audio Interrupt";
                //AudioInt.is_Data = NULL;
                AudioInt.is_Code = (void (*)())AudioFunc;

                // disable the DMA and interrupts
                custom->dmacon = DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3;
                custom->intena = INTF_AUD0|INTF_AUD2;
                custom->intreq = INTF_AUD0|INTF_AUD2;

                // SFX
                oldIntAud0 = SetIntVector(INTB_AUD0, &AudioInt);
                curSoundBuffer = 0;

                // left channel
                custom->aud[0].ac_len = SND_SAMPLES / sizeof(UWORD);
                custom->aud[0].ac_per = period;
                custom->aud[0].ac_vol = 64;
                custom->aud[0].ac_ptr = (UWORD *)soundBuffer;

                // right channel
                custom->aud[1].ac_len = SND_SAMPLES / sizeof(UWORD);
                custom->aud[1].ac_per = period;
                custom->aud[1].ac_vol = 64;
                custom->aud[1].ac_ptr = (UWORD *)soundBuffer;

                // Music
                oldIntAud2 = SetIntVector(INTB_AUD2, &AudioInt);
                curMusicBuffer = 0;

                // left channel
                custom->aud[2].ac_len = SND_SAMPLES / sizeof(UWORD);
                custom->aud[2].ac_per = period;
                custom->aud[2].ac_vol = 64;
                custom->aud[2].ac_ptr = (UWORD *)musicBuffer;

                // right channel
                custom->aud[3].ac_len = SND_SAMPLES / sizeof(UWORD);
                custom->aud[3].ac_per = period;
                custom->aud[3].ac_vol = 64;
                custom->aud[3].ac_ptr = (UWORD *)musicBuffer;

                // enable the DMA and interrupts
                custom->intena = INTF_SETCLR|INTF_AUD0|INTF_AUD2;
                custom->dmacon = DMAF_SETCLR|DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3;

                // turn on the low-pass filter
                oldFilter = ciaa->ciapra & CIAF_LED;
                ciaa->ciapra &= ~CIAF_LED;

                return;
            }
        }
    }

    sndFree();
}

void sndInitSamples()
{
    // nothing to do
}

void sndFreeSamples()
{
    // nothing to do
}

void* sndPlaySample(int32 index, int32 volume, int32 pitch, int32 mode)
{
    if (!gSettings.audio_sfx)
        return NULL;

    const uint8 *data = level.soundData + level.soundOffsets[index];
    int32 size = data[0] | data[1] << 8 | data[2] << 16 | data[3] << 24;
    data += 4;

    if (mode == UNIQUE || mode == REPLAY)
    {
        for (int32 i = 0; i < channelsCount; i++)
        {
            Sample* sample = channels + i;

            if (sample->data != data)
                continue;

            sample->inc = CALC_INC;
            sample->volume = volume;

            if (mode == REPLAY)
            {
                sample->pos = 0;
            }

            return sample;
        }
    }

    if (channelsCount >= SND_CHANNELS)
        return NULL;

    Sample* sample = channels + channelsCount++;
    sample->data = data;
    sample->size = size << SND_FIXED_SHIFT;
    sample->pos  = 0;
    sample->inc  = CALC_INC;
    sample->volume = volume;

    return sample;
}

void sndPlayTrack(int32 track)
{
    if (!gSettings.audio_music)
        return;

    if (track == gCurTrack)
        return;

    gCurTrack = track;

    if (track == -1) {
        sndStopTrack();
        return;
    }


    int32 pctrack = -1;
    switch (track)
    {
        // TODO track 3
        case TRACK_TR1_TITLE:
            pctrack = 2;
            break;

        case TRACK_TR1_CAVES:
            pctrack = 3;
            break;

        case TRACK_TR1_CISTERN:
            pctrack = 4;
            break;

        case TRACK_TR1_WIND:
            pctrack = 5;
            break;

        case TRACK_TR1_PYRAMID:
            pctrack = 6;
            break;

        case TRACK_TR1_CUT_1:
            pctrack = 8;
            break;

        case TRACK_TR1_CUT_2:
            pctrack = 10;
            break;

        case TRACK_TR1_CUT_3:
            pctrack = 9;
            break;

        case TRACK_TR1_CUT_4:
            pctrack = 7;
            break;
    }

    if (pctrack < 0)
        return;

    char buf[32] = "audio/track_00.ad4";
    buf[12] += pctrack / 10;
    buf[13] += pctrack % 10;

    BPTR f = Open(buf, MODE_OLDFILE);

    if (!f)
        return;

    //sndStopTrack();
    if (music.data)
    {
        delete[] music.data;
        music.data = NULL;
        memset(musicBuffer, 0, sizeof(musicBuffer));
    }

    Seek(f, 0, OFFSET_END);
    int32 size = Seek(f, 0, OFFSET_CURRENT);
    Seek(f, 0, OFFSET_BEGINNING);
    uint8* data = new uint8[size];
    Read(f, data, size);
    Close(f);

    // Clear music.data before setup, and write it after to ensure
    // music.fill() has a consistent state at any point in time
    //music.data = NULL;
    music.size = size;
    music.pos = 0;
    //music.volume = (1 << SND_VOL_SHIFT);
    music.state.zM1   = 0;
    music.state.zM2   = 0;
    music.state.tap   = 0;
    music.state.quant = 0x0800;
    music.data = data;
}

void sndStopTrack()
{
    if (music.data)
    {
        delete[] music.data;
        music.data = NULL;
        memset(musicBuffer, SND_ENCODE(0), sizeof(musicBuffer));
    }
    music.size = 0;
    music.pos = 0;
    gCurTrack = -1;
}

bool sndTrackIsPlaying()
{
    return gCurTrack != -1;
    //return music.data != NULL;
}

void sndStopSample(int32 index)
{
    const uint8 *data = level.soundData + level.soundOffsets[index] + 4;

    int32 i = channelsCount;

    while (--i >= 0)
    {
        if (channels[i].data == data)
        {
            channels[i] = channels[--channelsCount];
        }
    }
}

void sndStop()
{
    channelsCount = 0;
    //music.data = NULL;
    sndStopTrack();
}

void sndFill(int8* buffer)
{
#ifdef PROFILE_SOUNDTIME
    PROFILE_CLEAR();
    PROFILE(CNT_SOUND);
#endif
    bool mix = false;

    memset(buffer, SND_ENCODE(0), SND_SAMPLES);
    int32 ch = channelsCount;
    while (ch--)
    {
        Sample* sample = channels + ch;

        if (mix)
            sample->mix(buffer);
        else
            sample->fill(buffer);

        if (!sample->data) {
            channels[ch] = channels[--channelsCount];
        }

        mix = true;
    }
}
