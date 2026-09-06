;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _getSector_asm
    XDEF getSector_asm

_getSector_asm:
getSector_asm:
    move.l d2,-(sp)
    move.l 4(a0),a1
    move.l 8(a0),a0

    ; sx: clamp((x - info->x<<8) >> 10, 0, xSectors-1)
    move.w (a1),d2
    ext.l d2
    asl.l #8,d2
    sub.l d2,d0
    asr.l #8,d0
    asr.l #2,d0
    tst.l d0
    blt .sx_lo
    moveq #0,d2
    move.b 20(a1),d2
    cmp.l d2,d0
    blt .sx_done
    move.l d2,d0
    subq.l #1,d0
    bra .sx_done

.sx_lo:
    moveq #0,d0

.sx_done:
    ; sz: clamp((z - info->z<<8) >> 10, 0, zSectors-1)
    move.w 2(a1),d2
    ext.l d2
    asl.l #8,d2
    sub.l d2,d1
    asr.l #8,d1
    asr.l #2,d1
    moveq #0,d2
    move.b 21(a1),d2
    tst.l d1
    blt .sz_lo
    cmp.l d2,d1
    blt .sz_done
    move.l d2,d1
    subq.l #1,d1
    bra .sz_done

.sz_lo:
    moveq #0,d1

.sz_done:
    ; return sectors + sx * zSectors + sz (sizeof(Sector) = 8)
    muls.w d2,d0
    add.l d1,d0
    asl.l #3,d0
    add.l a0,d0
    move.l (sp)+,d2
    rts
