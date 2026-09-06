;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _sndADPCM4_fill_asm
    XDEF sndADPCM4_fill_asm
    XDEF _sndPCM_fill_asm
    XDEF sndPCM_fill_asm
    XDEF _sndPCM_mix_asm
    XDEF sndPCM_mix_asm

    XREF _ADPCM4_ADAPT

; void sndADPCM4_fill_asm(ADPCM4_STATE &state, int8* buffer, const uint8* data, int32 size)
; a0=state, a1=buffer, a2=data, d0=size
_sndADPCM4_fill_asm:
sndADPCM4_fill_asm:
    movem.l d2-d7/a2-a5,-(sp)
    move.l d0,d7

    ; load decoder state: zM1, zM2, tap, quant
    move.l (a0),d2
    move.l 4(a0),d3
    move.l 8(a0),d4
    move.l 12(a0),d5

    bra .adpcm_loop_test

.adpcm_loop:
    ; each byte = two nibbles
    moveq #0,d6
    move.b (a2)+,d6

    ; decode low nibble
    bsr .adpcm_decode_nibble

    ; shift down, decode high nibble
    lsr.l #4,d6
    bsr .adpcm_decode_nibble

    subq.l #1,d7

.adpcm_loop_test:
    tst.l d7
    bgt .adpcm_loop

    ; store decoder state
    move.l d2,(a0)
    move.l d3,4(a0)
    move.l d4,8(a0)
    move.l d5,12(a0)

    movem.l (sp)+,d2-d7/a2-a5
    rts

; decode one ADPCM4 nibble
; in: d6=nibble, d2=zM1, d3=zM2, d4=tap, d5=quant
; out: updated d2-d5, a1 advanced
.adpcm_decode_nibble:
    ; tap = zM2 + tap - (tap >> 3)
    move.l d4,d0
    asr.l #3,d0
    add.l d3,d4
    sub.l d0,d4

    ; clamp tap>>8 to [-128,127] and emit
    move.l d4,d0
    asr.l #8,d0
    cmp.l #-128,d0
    bge .adpcm_clamp_hi
    move.l #-128,d0
    bra .adpcm_clamp_done

.adpcm_clamp_hi:
    cmp.l #127,d0
    ble .adpcm_clamp_done
    move.l #127,d0

.adpcm_clamp_done:
    ; Amiga: SND_ENCODE is identity, write clamped value
    move.b d0,(a1)+

    ; res = ((n & 0xF) ^ 8) - 8  (sign-extend the 4-bit nibble)
    move.l d6,d0
    and.l #15,d0
    eor.l #8,d0
    sub.l #8,d0

    ; out = res*quant + (zM1 - zM2)
    move.l d0,d1
    muls.l d5,d1
    move.l d2,d0
    sub.l d3,d0
    add.l d0,d1

    ; shift history: zM2=zM1, zM1=out
    move.l d2,d3
    move.l d1,d2

    ; quant = (quant * ADPCM4_ADAPT[res+8] + 127) >> 7
    move.l d6,d0
    and.l #15,d0
    eor.l #8,d0
    sub.l #8,d0
    add.l #8,d0
    lea _ADPCM4_ADAPT,a3
    moveq #0,d1
    move.b (a3,d0.l),d1
    muls.l d1,d5
    add.l #127,d5
    asr.l #7,d5
    rts

; int32 sndPCM_fill_asm(int32 pos, int32 inc, int32 size, int32 volume, const uint8* data, int8* buffer)
; d0=pos, d1=inc, d2=size, d3=volume, a0=data, a1=buffer
_sndPCM_fill_asm:
sndPCM_fill_asm:
    movem.l d2-d6/a2-a3,-(sp)
    move.l a0,a2
    move.l a1,a3

    ; last = pos + 1024 * inc
    move.l d0,d4
    move.l d1,d5
    asl.l #8,d5
    asl.l #2,d5
    add.l d5,d4

    ; clamp last to size
    cmp.l d2,d4
    ble .fill_last_ok
    move.l d2,d4

.fill_last_ok:
    ; full volume (64): skip multiply
    cmp.l #64,d3
    bne .fill_vol

.fill_full_loop:
    cmp.l d4,d0
    bge .fill_done

    ; *buffer++ = data[pos >> 8] - 128
    move.l d0,d5
    asr.l #8,d5
    moveq #0,d6
    move.b (a2,d5.l),d6
    sub.l #128,d6
    move.b d6,(a3)+

    add.l d1,d0
    bra .fill_full_loop

.fill_vol:
    ; volume-scaled path
.fill_vol_loop:
    cmp.l d4,d0
    bge .fill_done

    move.l d0,d5
    asr.l #8,d5
    moveq #0,d6
    move.b (a2,d5.l),d6
    sub.l #128,d6
    muls.l d3,d6
    asr.l #6,d6
    move.b d6,(a3)+

    add.l d1,d0
    bra .fill_vol_loop

.fill_done:
    move.l d0,d0
    movem.l (sp)+,d2-d6/a2-a3
    rts

; int32 sndPCM_mix_asm(int32 pos, int32 inc, int32 size, int32 volume, const uint8* data, int8* buffer)
; d0=pos, d1=inc, d2=size, d3=volume, a0=data, a1=buffer
; same as fill but mixes into existing buffer
_sndPCM_mix_asm:
sndPCM_mix_asm:
    movem.l d2-d6/a2-a3,-(sp)
    move.l a0,a2
    move.l a1,a3

    ; last = pos + 1024 * inc
    move.l d0,d4
    move.l d1,d5
    asl.l #8,d5
    asl.l #2,d5
    add.l d5,d4

    cmp.l d2,d4
    ble .mix_last_ok
    move.l d2,d4

.mix_last_ok:
    ; inc goes in d2, size no longer needed
    move.l d1,d2

    cmp.l #64,d3
    bne .mix_vol

    ; Full-volume mix path
.mix_full_loop:
    cmp.l d4,d0
    bge .mix_done

    ; amp = *buffer + (data[pos >> 8] - 128)
    move.b (a3),d5
    extb.l d5
    move.l d0,d6
    asr.l #8,d6
    moveq #0,d1
    move.b (a2,d6.l),d1
    sub.l #128,d1
    add.l d1,d5

    ; clamp to [-128,127]
    cmp.l #-128,d5
    bge .mix_full_clamp_hi
    move.l #-128,d5
    bra .mix_full_clamp_done

.mix_full_clamp_hi:
    cmp.l #127,d5
    ble .mix_full_clamp_done
    move.l #127,d5

.mix_full_clamp_done:
    move.b d5,(a3)+

    add.l d2,d0
    bra .mix_full_loop

.mix_vol:

    ; volume-scaled mix path
.mix_vol_loop:
    cmp.l d4,d0
    bge .mix_done

    move.b (a3),d5
    extb.l d5
    move.l d0,d6
    asr.l #8,d6
    moveq #0,d1
    move.b (a2,d6.l),d1
    sub.l #128,d1
    muls.l d3,d1
    asr.l #6,d1
    add.l d1,d5

    ; clamp to [-128,127]
    cmp.l #-128,d5
    bge .mix_vol_clamp_hi
    move.l #-128,d5
    bra .mix_vol_clamp_done

.mix_vol_clamp_hi:
    cmp.l #127,d5
    ble .mix_vol_clamp_done
    move.l #127,d5

.mix_vol_clamp_done:
    move.b d5,(a3)+

    add.l d2,d0
    bra .mix_vol_loop

.mix_done:
    move.l d0,d0
    movem.l (sp)+,d2-d6/a2-a3
    rts
