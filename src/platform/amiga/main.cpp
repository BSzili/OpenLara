#include "game.h"

#define Object AmiObject
#include <proto/dos.h>
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>
#include <graphics/videocontrol.h>
#include <workbench/startup.h>
#include <clib/alib_protos.h>
#include <clib/debug_protos.h>
#include <proto/intuition.h>
#include <exec/execbase.h>
#include <proto/exec.h>
#include <proto/keymap.h>
#include <proto/lowlevel.h>
#include <proto/dos.h>
//#include <proto/timer.h>
#include <proto/graphics.h>
#include <proto/icon.h>

#include <cybergraphx/cybergraphics.h>
#include <proto/cybergraphics.h>

#include <SDI_compiler.h>

//#define ECSHACK


static struct Window *window;
static struct Screen *screen;
static UWORD *pointermem;
struct Library *CyberGfxBase;
static int currentBitMap;
static struct ScreenBuffer *sbuf[2];
static int use_c2p = 0;
static ULONG fsMonitorID = INVALID_ID;

extern "C" void ASM c2p1x1_8_c5_bm(REG(d0, WORD chunkyx), REG(d1, WORD chunkyy), REG(d2, WORD offsx), REG(d3, WORD offsy), REG(a0, APTR chunkyscreen), REG(a1, struct BitMap *bitmap));
#ifdef ECSHACK
extern "C" void ASM c2p1x1_4_c5_bm_word(REG(d0, WORD chunkyx), REG(d1, WORD chunkyy), REG(d2, WORD offsx), REG(d3, WORD offsy), REG(a0, APTR chunkyscreen), REG(a1, struct BitMap *bitmap));
static UWORD ecsPalette[16] = { 0x0000, 0x0111, 0x0222, 0x0333, 0x0444, 0x0555, 0x0666, 0x0777, 0x0888, 0x0999, 0x0AAA, 0x0BBB, 0x0CCC, 0x0DDD, 0x0EEE, 0x0FFF };
static uint8 ecsfb[FRAME_WIDTH*FRAME_HEIGHT];
static uint8 ecsRemap[256];
#endif


static ULONG timecount;
static struct EClockVal timeval;
int32 g_timer;
int32 fps;
int32 frameIndex = 0;
int32 fpsCounter = 0;
uint32 curSoundBuffer = 0;

//uint8 gLightmap[256 * 32];
uint8* gLightmap;

const void* TRACKS_IMA;
const void* TITLE_SCR;
const void* levelData;

#define KB_A        0x20
#define KB_S        0x21
#define KB_Z        0x31
#define KB_X        0x32
#define KB_SPACE    0x40
#define KB_TAB      0x42
#define KB_ENTER    0x44
#define KB_ESC      0x45
#define KB_DEL      0x46
#define KB_UP       0x4C
#define KB_DOWN     0x4D
#define KB_RIGHT    0x4E
#define KB_LEFT     0x4F
#define KB_HELP     0x5F
#define KB_F10      0x59
#define KB_LSHIFT   0x60
#define KB_RSHIFT   0x61
#define KB_CTRL     0x63
#define KB_LALT     0x64
#define KB_RALT     0x65


static APTR timerIntHandle = NULL;
static APTR keyIntHandle = NULL;

bool keyState[128];

extern int    __argc;
extern char **__argv;
static void parseTooltypes(void)
{
    char *exename;
    struct DiskObject *appicon;

    if (__argc == 0) {
        struct WBStartup *startup = (struct WBStartup *)__argv;
        exename = (char *)startup->sm_ArgList->wa_Name;
    } else {
        exename = __argv[0];
    }

    if ((appicon = GetDiskObject((STRPTR)exename))) {
        char *value;

        if ((value = (char *)FindToolType((STRPTR *)appicon->do_ToolTypes, (CONST_STRPTR)"FORCEMODE"))) {
            if (!strcmp(value, "NTSC"))
                fsMonitorID = NTSC_MONITOR_ID;
            else if (!strcmp(value, "PAL"))
                fsMonitorID = PAL_MONITOR_ID;
            else if (!strcmp(value, "MULTISCAN"))
                fsMonitorID = VGA_MONITOR_ID;
            else if (!strcmp(value, "EURO72"))
                fsMonitorID = EURO72_MONITOR_ID;
            else if (!strcmp(value, "EURO36"))
                fsMonitorID = EURO36_MONITOR_ID;
            else if (!strcmp(value, "SUPER72"))
                fsMonitorID = SUPER72_MONITOR_ID;
            else if (!strcmp(value, "DBLNTSC"))
                fsMonitorID = DBLNTSC_MONITOR_ID;
            else if (!strcmp(value, "DBLPAL"))
                fsMonitorID = DBLPAL_MONITOR_ID;
        }
        FreeDiskObject(appicon);
    }
}

void setVideoMode()
{
    ULONG modeID = INVALID_ID;

    parseTooltypes();
#ifdef ECSHACK
    modeID = BestModeID(
        BIDTAG_NominalWidth, FRAME_WIDTH,
        BIDTAG_NominalHeight, FRAME_HEIGHT,
        BIDTAG_Depth, 4,
        (fsMonitorID == (ULONG)INVALID_ID) ? TAG_IGNORE : BIDTAG_MonitorID, fsMonitorID,
        TAG_DONE);
#else
    CyberGfxBase = OpenLibrary((STRPTR)"cybergraphics.library", 41);
    if (fsMonitorID == (ULONG)INVALID_ID && CyberGfxBase)
    {
        modeID = BestCModeIDTags(
            CYBRBIDTG_Depth, 8,
            CYBRBIDTG_NominalWidth, FRAME_WIDTH,
            CYBRBIDTG_NominalHeight, FRAME_HEIGHT,
            TAG_DONE);
    }

    if (modeID == (ULONG)INVALID_ID)
    {
        modeID = BestModeID(
            BIDTAG_NominalWidth, FRAME_WIDTH,
            BIDTAG_NominalHeight, FRAME_HEIGHT,
            BIDTAG_Depth, 8,
            //BIDTAG_DIPFMustNotHave, SPECIAL_FLAGS|DIPF_IS_LACE,
            (fsMonitorID == (ULONG)INVALID_ID) ? TAG_IGNORE : BIDTAG_MonitorID, fsMonitorID,
            TAG_DONE);
        //kprintf("%s native ID: %08lx\n", __FUNCTION__, modeID);
    }
#endif

    struct TagItem vctl[] =
    {
        //{VTAG_BORDERBLANK_SET, TRUE},
        {VC_IntermediateCLUpdate, FALSE},
        {VTAG_END_CM, 0}
    };

    screen = OpenScreenTags(0,
        modeID != (ULONG)INVALID_ID ? SA_DisplayID : TAG_IGNORE, modeID,
#ifdef ECSHACK
        SA_Depth, 4,
#else
        SA_Depth, 8,
#endif
        SA_ShowTitle, FALSE,
        SA_Quiet, TRUE,
        SA_Draggable, FALSE,
        SA_Type, CUSTOMSCREEN,
        SA_VideoControl, (ULONG)vctl,
        //SA_DetailPen, blackcol,
        //SA_BlockPen, whitecol,
        //SA_Overscan, OSCAN_MAX,
        TAG_DONE);

#ifdef ECSHACK
    LoadRGB4(&screen->ViewPort, ecsPalette, 16);
#endif

    window = OpenWindowTags(0,
        WA_InnerWidth, (ULONG)screen->Width,
        WA_InnerHeight, (ULONG)screen->Height,
        WA_Flags, WFLG_ACTIVATE | WFLG_RMBTRAP | WFLG_BACKDROP | WFLG_BORDERLESS,
        WA_CustomScreen, (ULONG)screen,
        TAG_DONE);

    use_c2p = FALSE;
    if ((GetBitMapAttr(screen->RastPort.BitMap, BMA_FLAGS) & BMF_STANDARD)) {
        if (!(sbuf[0] = AllocScreenBuffer(screen, 0, SB_SCREEN_BITMAP)) || !(sbuf[1] = AllocScreenBuffer(screen, 0, SB_COPY_BITMAP))) {
            return; // TODO fallback to WCP?
        }

        use_c2p = TRUE;
    }

    pointermem = (UWORD *)AllocVec(2 * 6, MEMF_CHIP | MEMF_CLEAR);
    if (pointermem && window->Pointer != pointermem) {
        SetPointer(window, pointermem, 1, 1, 0, 0);
    }
}

void setTextMode()
{
    if (sbuf[0])
    {
        FreeScreenBuffer(screen, sbuf[0]);
        sbuf[0] = NULL;
    }
    if (sbuf[1])
    {
        FreeScreenBuffer(screen,sbuf[1]);
        sbuf[1] = NULL;
    }
    if (window) {
        CloseWindow(window);
        window = NULL;
    }
    if (screen) {
        CloseScreen(screen);
        screen = NULL;
    }
    if (pointermem) {
        FreeVec(pointermem);
        pointermem = NULL;
    }
    if (CyberGfxBase) {
        CloseLibrary(CyberGfxBase);
        CyberGfxBase = NULL;
    }
}

void osSetPalette(const uint16* palette)
{

#ifdef ECSHACK
    for (int32 i = 0; i < 256; i++)
    {
        uint16 p = *palette++;

        uint8 r = (p & 31);
        uint8 g = ((p >> 5) & 31);
        uint8 b = ((p >> 10) & 31);

        uint32 lum = (r * 77 + g * 150 + b * 29) >> 9;
        ecsRemap[i] = lum;
    }
#else
    static ULONG spal[1 + (256 * 3) + 1];
    ULONG *sp = spal;

    *sp++ = 256 << 16;
    for (int32 i = 0; i < 256; i++)
    {
        uint16 c = *palette++;
        //kprintf("%s %3lu %4lx\n", __FUNCTION__, i, c);
        *sp++ = (ULONG)(c & 0x1F) << 27;
        *sp++ = (ULONG)((c >> 5) & 0x1F) << 27;
        *sp++ = (ULONG)((c >> 10) & 0x1F) << 27;
    }
    *sp = 0;
    LoadRGB32(&screen->ViewPort, spal);
#endif
}

void timerISR()
{
    frameIndex++;
}

void videoAcquire()
{
    setVideoMode();

    timerIntHandle = AddTimerInt((APTR)timerISR, NULL);
    if (timerIntHandle != NULL)
    {
        StartTimerInt(timerIntHandle, (1000 * 1000) / 60, TRUE);
    }
}

void videoRelease()
{
    if (timerIntHandle != NULL)
    {
        StopTimerInt(timerIntHandle);
        RemTimerInt(timerIntHandle);
        timerIntHandle = NULL;
    }
    setTextMode();
}

void waitVBlank()
{
    //WaitTOF();
}

void blit()
{
    if (use_c2p) {
        //WriteChunkyPixels(window->RPort, 0, 0, FRAME_WIDTH - 1, FRAME_HEIGHT - 1, (UBYTE *)fb, FRAME_WIDTH);
        currentBitMap ^= 1;
#ifdef ECSHACK
        for (uint32 i = 0; i < FRAME_WIDTH*FRAME_HEIGHT; i++)
        {
            ecsfb[i] = ecsRemap[fb[i]];
        }
        c2p1x1_4_c5_bm_word(FRAME_WIDTH, FRAME_HEIGHT, 0, 0, ecsfb, sbuf[currentBitMap]->sb_BitMap);
#else
        c2p1x1_8_c5_bm(FRAME_WIDTH, FRAME_HEIGHT, 0, 0, fb, sbuf[currentBitMap]->sb_BitMap);
#endif
        ChangeScreenBuffer(screen, sbuf[currentBitMap]);
    } else if (CyberGfxBase) {
        WritePixelArray(fb, 0, 0, FRAME_WIDTH, window->RPort, 0, 0, FRAME_WIDTH, FRAME_HEIGHT, RECTFMT_LUT8);
    }
}

void keyISR(REG(d0,ULONG scancode))
{
    keyState[scancode & 0x7F] = ((scancode & 0x80) == 0);
    //kprintf("%s %lx = %lu\n", __FUNCTION__, scancode & 0x7F, ((scancode & 0x80) == 0));
}

void inputAcquire()
{
    keyIntHandle = AddKBInt((APTR)keyISR, NULL);
}

void inputRelease()
{
    if (keyIntHandle != NULL)
    {
        RemKBInt(keyIntHandle);
        keyIntHandle = NULL;
    }
}

void inputUpdate()
{
    keys = 0;
    if (keyState[KB_UP])      keys |= IK_UP;
    if (keyState[KB_RIGHT])   keys |= IK_RIGHT;
    if (keyState[KB_DOWN])    keys |= IK_DOWN;
    if (keyState[KB_LEFT])    keys |= IK_LEFT;
    if (keyState[KB_CTRL])       keys |= IK_A;
    if (keyState[KB_DEL])       keys |= IK_B;
    if (keyState[KB_LALT])       keys |= IK_X;
    if (keyState[KB_RALT])       keys |= IK_X;
    if (keyState[KB_HELP])       keys |= IK_L;
    if (keyState[KB_LSHIFT])       keys |= IK_R;
    if (keyState[KB_RSHIFT])       keys |= IK_R;
    if (keyState[KB_SPACE])       keys |= IK_Y;
    if (keyState[KB_ESC])   keys |= IK_SELECT;;
    ULONG portState = ReadJoyPort(1);
    if (portState)
    {
        if (portState & JPF_JOY_UP) keys |= IK_UP;
        if (portState & JPF_JOY_DOWN)   keys |= IK_DOWN;
        if (portState & JPF_JOY_RIGHT)  keys |= IK_RIGHT;
        if (portState & JPF_JOY_LEFT)   keys |= IK_LEFT;
        if (portState & JPF_BUTTON_REVERSE) keys |= IK_L; // look
        if (portState & JPF_BUTTON_FORWARD) keys |= IK_R; // walk
        if (portState & JPF_BUTTON_GREEN)   keys |= IK_X; // jump
        if (portState & JPF_BUTTON_BLUE)    keys |= IK_B; // roll
        if (portState & JPF_BUTTON_YELLOW)  keys |= IK_Y; // weapon
        if (portState & JPF_BUTTON_RED) keys |= IK_A; // action
        if (portState & JPF_BUTTON_PLAY)    keys |= IK_SELECT;
    }
    //static uint32 oldkeys = 0;if (keys!=oldkeys) {oldkeys =keys; kprintf("%s keys %04lx\n", __FUNCTION__, keys);}

}

int32 osGetSystemTimeMS()
{
    timecount += ElapsedTime(&timeval);
    return timecount >> 6; // TODO this is 2,4% slower
}

bool osSaveSettings()
{
    BPTR f = Open("settings.dat", MODE_NEWFILE);
    if (!f) return false;
    Write(f, &gSettings, sizeof(gSettings));
    Close(f);
    return true;
}

bool osLoadSettings()
{
    BPTR f = Open("settings.dat", MODE_OLDFILE);
    if (!f) return false;
    uint8 version;
    Read(f, &version, 1);
    if (version != gSettings.version) {
        Close(f);
        return false;
    }
    Read(f, (uint8*)&gSettings + 1, sizeof(gSettings) - 1);
    Close(f);
    return true;
}

bool osCheckSave()
{
    BPTR f = Open("savegame.dat", MODE_OLDFILE);
    if (!f) return false;
    Close(f);
    return true;
}

bool osSaveGame()
{
    BPTR f = Open("savegame.dat", MODE_NEWFILE);
    if (!f) return false;
    Write(f, &gSaveGame, sizeof(gSaveGame));
    Write(f, &gSaveData, gSaveGame.dataSize);
    Close(f);
    return true;
}

bool osLoadGame()
{
    BPTR f = Open("savegame.dat", MODE_OLDFILE);

    if (!f) return false;

    uint32 version;
    Read(f, &version, sizeof(version));

    if (SAVEGAME_VER != version)
    {
        Close(f);
        return false;
    }

    Read(f, &gSaveGame.dataSize, sizeof(gSaveGame) - sizeof(version));
    Read(f, &gSaveData, gSaveGame.dataSize);
    Close(f);
    return true;
}

void osJoyVibrate(int32 index, int32 L, int32 R) {}

const void* osLoadScreen(LevelID id)
{
    if (!TITLE_SCR)
    {
        uint8* data = new uint8[FRAME_WIDTH * FRAME_HEIGHT];
        memset(data, 0, FRAME_WIDTH * FRAME_HEIGHT);
        BPTR f = Open("data/TITLE.SCR", MODE_OLDFILE);
        if (f)
        {
            Read(f, data, FRAME_WIDTH * FRAME_HEIGHT);
            Close(f);
        }

        TITLE_SCR = data;
    }
    return TITLE_SCR;
}

const void* osLoadLevel(LevelID id)
{
    char buf[32];

    if (levelData)
    {
        delete[] levelData;
    }

    strcpy(buf, "data/");
    strcat(buf, (const char*)gLevelInfo[id].data);
#if (USE_FMT & LVL_FMT_PKD)
    strcat(buf, ".PKD");
#endif
#if (USE_FMT & LVL_FMT_PHD)
    strcat(buf, ".PHD");
#endif
#if (USE_FMT & LVL_FMT_PSX)
    strcat(buf, ".PSX");
#endif

    BPTR f = Open(buf, MODE_OLDFILE);

    if (!f)
        return NULL;

    {
        Seek(f, 0, OFFSET_END);
        int32 size = Seek(f, 0, OFFSET_CURRENT);
        Seek(f, 0, OFFSET_BEGINNING);
        uint8* data = new uint8[size];
        Read(f, data, size);
        Close(f);

        levelData = data;
    }
#if 0
// tracks
    if (!TRACKS_IMA)
    {
        FILE *f = fopen("data/TRACKS.IMA", "rb");
        if (!f)
            return NULL;

        fseek(f, 0, SEEK_END);
        int32 size = ftell(f);
        fseek(f, 0, SEEK_SET);
        uint8* data = new uint8[size];
        fread(data, 1, size, f);
        Close(f);

        TRACKS_IMA = data;
    }
#endif

    return (void*)levelData;
}

APTR AllocMemAligned(ULONG byteSize, ULONG attributes, ULONG alignSize, ULONG alignOffset)
{
    ULONG totalSize = byteSize + alignSize - 1 + alignOffset;
    APTR finalMem = NULL;
    APTR rawMem = AllocMem(totalSize, attributes);
    if (rawMem)
    {
        Forbid();
        APTR aligned_mem = (APTR)((((ULONG)rawMem + alignSize - 1) & ~(alignSize - 1)) - alignOffset);
        FreeMem(rawMem, totalSize);
        finalMem = AllocAbs(byteSize, aligned_mem);
        Permit();
    }
    return finalMem;
}

int main(void)
{
    videoAcquire();
    inputAcquire();

    timecount = 0;
    ElapsedTime(&timeval);
#ifdef ALIGNED_LIGHTMAP
    gLightmap = (uint8*)AllocMemAligned(256 * 32, MEMF_ANY, 0x10000, 0);
#else
    gLightmap = (uint8*)AllocMem(256 * 32, MEMF_ANY);
#endif

    //gLevelID = LVL_TR1_1;
    gLevelID = LVL_TR1_TITLE;
    //gLevelID = LVL_TR1_GYM;
    gameInit();

    int32 lastFrameIndex = -1;

    //int extraFrame = 0;

    while (1)
    {
        inputUpdate();

        if (keyState[KB_F10])
            break;

        int32 frame = frameIndex / 2;
        int32 delta = frame - lastFrameIndex;

        if (!delta)
            continue;
        lastFrameIndex = frame;

        gameUpdate(delta);

        #ifdef PROFILING
            waitVBlank();
        #else
            if (gSettings.video_vsync) {
                waitVBlank();
            }
        #endif

        gameRender();

        fpsCounter++;
        if (frameIndex >= 60) {
            frameIndex -= 60;
            lastFrameIndex -= 30;

            fps = fpsCounter;

            fpsCounter = 0;
        }

        blit();
    }

    FreeMem(gLightmap, 256 * 32);

    inputRelease();
    videoRelease();

    return 0;
}

#define abs _abs_
#define itoa _itoa_
#include <stdlib.h>

struct _reent *_impure_ptr;

void* operator new(size_t size)
{
    void* ptr = malloc(size);
    return ptr;
}

void* operator new[](size_t size)
{
    void* ptr = malloc(size);
    return ptr;
}

void operator delete(void* ptr) noexcept
{
    free(ptr);
}

void operator delete[](void* ptr) noexcept
{
    free(ptr);
}

void operator delete(void* ptr, size_t size) noexcept
{
    free(ptr);
}

void operator delete[](void* ptr, size_t size) noexcept
{
    free(ptr);
}
