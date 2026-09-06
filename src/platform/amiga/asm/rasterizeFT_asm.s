;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _rasterizeFT_asm
    XDEF rasterizeFT_asm

; Flat textured, no transparency
_rasterizeFT_asm:
rasterizeFT_asm:
    movem.l d2-d7/a2-a6,-(sp)
    sub.l #40,sp

    move.l _gLightmap,a3
    move.l _gTile,a4
    lea _divTable,a5

    ; ft_lightmap = &gLightmap[shade << 8]
    moveq #0,d6
    move.b 6(a1),d6
    lsl.l #8,d6
    lea (a3,d6.l),a3

    clr.l d0
    clr.l d1
    clr.l 0(sp)
    clr.l 4(sp)
    clr.l 8(sp)
    clr.l 12(sp)

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

    move.l 8(a1),d4

    cmp.l #1,d0
    ble .L_shift

    move.l d0,d6
    move.w (a5,d6.w*2),d6

    move.w 0(a6),d7
    sub.w d2,d7
    muls.w d6,d7
    move.l d7,0(sp)

    move.l 8(a6),d7
    sub.l d4,d7

    move.l d7,36(sp)
    swap d7
    muls.w d6,d7
    move.l d7,16(sp)

    move.l 36(sp),d7
    muls.w d6,d7

    move.l 16(sp),d6
    swap d7
    move.w d7,d6
    move.l d6,8(sp)

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

    move.l 8(a2),d5

    cmp.l #1,d1
    ble .R_shift

    move.l d1,d6
    move.w (a5,d6.w*2),d6

    move.w 0(a6),d7
    sub.w d3,d7
    muls.w d6,d7
    move.l d7,4(sp)

    move.l 8(a6),d7
    sub.l d5,d7

    move.l d7,36(sp)
    swap d7
    muls.w d6,d7
    move.l d7,16(sp)

    move.l 36(sp),d7
    muls.w d6,d7

    move.l 16(sp),d6
    swap d7
    move.w d7,d6
    move.l d6,12(sp)

.R_shift:
    swap d3
    clr.w d3
    move.l a6,a2
    bra .R_advance

.R_done:
    move.l d0,d6
    cmp.l d1,d6
    ble .h_ok
    move.l d1,d6

.h_ok:
    sub.l d6,d0
    sub.l d6,d1
    move.l d0,32(sp)
    move.l d1,28(sp)

    tst.l d6
    beq .outer_loop

    subq.l #1,d6
    move.l d6,24(sp)

.scanline_loop:
    move.l d2,d0
    swap d0
    ext.l d0

    move.l d3,d1
    swap d1
    ext.l d1
    sub.l d0,d1
    ble .scanline_skip

    move.l d1,20(sp)

    lea (a0,d0.l),a6

    move.l d1,d6
    move.w (a5,d6.w*2),d6

    move.l d5,d7
    sub.l d4,d7

    move.l d7,d0
    swap d7
    muls.w d6,d7
    move.l d7,d1

    move.l d0,d7
    muls.w d6,d7

    move.l d1,d6
    swap d7
    move.w d7,d6
    move.l d6,16(sp)

    move.l d4,d7

    ; odd start pixel
    move.l a6,d1
    and.l #1,d1
    beq .odd_start_done

    ; tile index = (v>>16)<<8 | (u>>24)
    move.l d7,d6
    swap d6
    lsr.w #8,d6

    move.l d7,d1
    and.l #$0000FF00,d1
    or.w d6,d1

    moveq #0,d6
    move.b (a4,d1.l),d6

    move.b (a3,d6.l),d6
    move.b d6,(a6)+

    add.l 16(sp),d7
    subq.l #1,20(sp)

.odd_start_done:
    ; odd tail pixel, sample at Rt-dtdx
    move.l 20(sp),d1
    and.l #1,d1
    beq .tail_done

    move.l d5,d0
    sub.l 16(sp),d0

    move.l d0,d6
    swap d6
    lsr.w #8,d6

    move.l d0,d1
    and.l #$0000FF00,d1
    or.w d6,d1

    moveq #0,d6
    move.b (a4,d1.l),d6

    move.b (a3,d6.l),d6
    move.l 20(sp),d1
    subq.l #1,d1
    move.b d6,(a6,d1.l)

.tail_done:
    ; 2-pixel loop, d4=dtdx*2
    move.l d4,36(sp)
    move.l 20(sp),d0
    lsr.l #1,d0
    beq .span_done

    subq.l #1,d0

    move.l 16(sp),d4
    asl.l #1,d4

.pix2_loop:
    move.l d7,d6
    swap d6
    lsr.w #8,d6

    move.l d7,d1
    and.l #$0000FF00,d1
    or.w d6,d1

    moveq #0,d6
    move.b (a4,d1.l),d6

    move.b (a3,d6.l),d6
    move.b d6,(a6)
    move.b d6,1(a6)
    addq.l #2,a6
    add.l d4,d7
    dbra d0,.pix2_loop

.span_done:
    move.l 36(sp),d4

.scanline_skip:
    lea 320(a0),a0

    add.l 0(sp),d2
    add.l 4(sp),d3
    add.l 8(sp),d4
    add.l 12(sp),d5

    subq.l #1,24(sp)
    bpl .scanline_loop

    move.l 32(sp),d0
    move.l 28(sp),d1
    bra .outer_loop

.return:
    add.l #40,sp
    movem.l (sp)+,d2-d7/a2-a6
    rts
