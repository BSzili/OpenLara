;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _rasterizeS_asm
    XDEF rasterizeS_asm

_rasterizeS_asm:
rasterizeS_asm:
    movem.l d2-d7/a2-a6,-(sp)
    sub.l #20,sp

    ; shadow lightmap at gLightmap+$1A00
    move.l _gLightmap,a3
    lea $1A00(a3),a3
    lea _divTable,a5

    clr.l d0
    clr.l d1
    clr.l 0(sp)
    clr.l 4(sp)

.outer_loop:

.L_advance:
    tst.l d0
    bne .L_done

    move.b 12(a1),d6
    extb.l d6
    asl.l #4,d6
    lea (a1,d6.l),a6

    move.w 2(a6),d7
    cmp.w 2(a1),d7
    blt .return

    move.w d7,d0
    sub.w 2(a1),d0
    ext.l d0

    move.w 0(a1),d2
    ext.l d2

    cmp.l #1,d0
    ble .L_shift

    move.l d0,d6
    move.w (a5,d6.w*2),d6

    move.w 0(a6),d7
    sub.w d2,d7
    muls.w d6,d7
    move.l d7,0(sp)

.L_shift:
    swap d2
    clr.w d2
    move.l a6,a1
    bra .L_advance

.L_done:

.R_advance:
    tst.l d1
    bne .R_done

    move.b 13(a2),d6
    extb.l d6
    asl.l #4,d6
    lea (a2,d6.l),a6

    move.w 2(a6),d7
    cmp.w 2(a2),d7
    blt .return

    move.w d7,d1
    sub.w 2(a2),d1
    ext.l d1

    move.w 0(a2),d3
    ext.l d3

    cmp.l #1,d1
    ble .R_shift

    move.l d1,d6
    move.w (a5,d6.w*2),d6

    move.w 0(a6),d7
    sub.w d3,d7
    muls.w d6,d7
    move.l d7,4(sp)

.R_shift:
    swap d3
    clr.w d3
    move.l a6,a2
    bra .R_advance

.R_done:

    ; h = min(Lh, Rh)
    move.l d0,d6
    cmp.l d1,d6
    ble .h_ok

    move.l d1,d6

.h_ok:
    sub.l d6,d0
    sub.l d6,d1
    move.l d0,16(sp)
    move.l d1,12(sp)

    tst.l d6
    beq .outer_loop

    subq.l #1,d6
    move.l d6,8(sp)

.scanline_loop:

    move.l d2,d0
    swap d0
    ext.l d0

    move.l d3,d1
    swap d1
    ext.l d1
    sub.l d0,d1
    ble .scanline_skip

    lea (a0,d0.l),a6
    subq.l #1,d1

    ; *ptr = shadow_lm[*ptr]
    moveq #0,d6

.shadow_loop:
    move.b (a6),d6
    move.b (a3,d6.l),d6
    move.b d6,(a6)+
    dbra d1,.shadow_loop

.scanline_skip:
    lea 320(a0),a0

    add.l 0(sp),d2
    add.l 4(sp),d3

    subq.l #1,8(sp)
    bpl .scanline_loop

    move.l 16(sp),d0
    move.l 12(sp),d1
    bra .outer_loop

.return:
    add.l #20,sp
    movem.l (sp)+,d2-d7/a2-a6
    rts
