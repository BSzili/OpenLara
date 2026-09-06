;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _rasterizeGTA_asm
    XDEF rasterizeGTA_asm

; Gouraud + textured + transparent. Skip write when tile index is 0
_rasterizeGTA_asm:
rasterizeGTA_asm:
    movem.l d2-d7/a2-a6,-(sp)
    sub.l #72,sp

    move.l _gLightmap,a3
    move.l _gTile,a4
    lea _divTable,a5

    clr.l d0
    clr.l d1
    clr.l 0(sp)
    clr.l 4(sp)
    clr.l 8(sp)
    clr.l 12(sp)
    clr.l 16(sp)
    clr.l 20(sp)

.outer_loop:
    ; advance left edge
    ; d0=Lh d2=Lx d4=Lt d6=Lg
.L_advance:
    tst.l d0
    bne .L_done

    move.l d1,64(sp)
    move.l d7,68(sp)

    ; N = L->prev
    move.b 12(a1),d7
    extb.l d7
    asl.l #4,d7
    lea (a1,d7.l),a6

    ; bail if edge goes backwards
    move.w 2(a6),d7
    cmp.w 2(a1),d7
    blt .return

    move.w d7,d0
    sub.w 2(a1),d0
    ext.l d0

    move.w 0(a1),d2
    ext.l d2

    moveq #0,d6
    move.b 6(a1),d6

    move.l 8(a1),d4

    cmp.l #1,d0
    ble .L_shift

    move.l d0,d7
    move.w (a5,d7.w*2),d7

    move.w 0(a6),d1
    sub.w d2,d1
    muls.w d7,d1
    move.l d1,0(sp)

    moveq #0,d1
    move.b 6(a6),d1
    sub.l d6,d1
    muls.w d7,d1
    asr.l #8,d1
    move.l d1,16(sp)

    ; duv = N->t - Lt (du hi, dv lo)
    move.l 8(a6),d1
    sub.l d4,d1

    move.l d1,56(sp)
    swap d1
    muls.w d7,d1
    move.l d1,32(sp)

    move.l 56(sp),d1
    muls.w d7,d1

    ; Ldt = du<<16 | dv>>16
    move.l 32(sp),d7
    swap d1
    move.w d1,d7
    move.l d7,8(sp)

.L_shift:
    move.l 64(sp),d1
    move.l 68(sp),d7
    swap d2
    clr.w d2
    lsl.l #8,d6
    move.l a6,a1
    bra .L_advance

.L_done:
    ; advance right edge
    ; d1=Rh d3=Rx d5=Rt d7=Rg
.R_advance:
    tst.l d1
    bne .R_done

    move.l d0,64(sp)
    move.l d2,68(sp)

    ; N = R->next
    move.b 13(a2),d0
    extb.l d0
    asl.l #4,d0
    lea (a2,d0.l),a6

    ; bail if edge goes backwards
    move.w 2(a6),d0
    cmp.w 2(a2),d0
    blt .return

    move.w d0,d1
    sub.w 2(a2),d1
    ext.l d1

    move.w 0(a2),d3
    ext.l d3

    moveq #0,d7
    move.b 6(a2),d7

    move.l 8(a2),d5

    cmp.l #1,d1
    ble .R_shift

    move.l d1,d0
    move.w (a5,d0.w*2),d0

    move.w 0(a6),d2
    sub.w d3,d2
    muls.w d0,d2
    move.l d2,4(sp)

    moveq #0,d2
    move.b 6(a6),d2
    sub.l d7,d2
    muls.w d0,d2
    asr.l #8,d2
    move.l d2,20(sp)

    ; duv = N->t - Rt
    move.l 8(a6),d2
    sub.l d5,d2

    move.l d2,56(sp)
    swap d2
    muls.w d0,d2
    move.l d2,32(sp)

    move.l 56(sp),d2
    muls.w d0,d2

    ; Rdt = du<<16 | dv>>16
    move.l 32(sp),d0
    swap d2
    move.w d2,d0
    move.l d0,12(sp)

.R_shift:
    move.l 64(sp),d0
    move.l 68(sp),d2
    swap d3
    clr.w d3
    lsl.l #8,d7
    move.l a6,a2
    bra .R_advance

.R_done:
    ; h = min(Lh, Rh)
    move.l d2,24(sp)
    move.l d3,28(sp)

    move.l d0,d2
    cmp.l d1,d2
    ble .h_ok
    move.l d1,d2

.h_ok:
    sub.l d2,d0
    sub.l d2,d1
    move.l d0,52(sp)
    move.l d1,48(sp)

    tst.l d2
    beq .outer_loop

    subq.l #1,d2
    move.l d2,44(sp)

    ; scanline
    ; d4=Lt d5=Rt d6=Lg d7=Rg
    ; Lx=24(sp) Rx=28(sp)
.scanline_loop:
    move.l 24(sp),d0
    swap d0
    ext.l d0

    move.l 28(sp),d1
    swap d1
    ext.l d1
    sub.l d0,d1
    ble .scanline_skip

    move.l d1,40(sp)

    lea (a0,d0.l),a6

    move.l d1,d2
    move.w (a5,d2.w*2),d2

    ; dgdx = (Rg-Lg)/width >> 15
    move.l d7,d1
    sub.l d6,d1
    muls.l d2,d1
    asr.l #7,d1
    asr.l #8,d1
    move.l d1,36(sp)

    ; dtdx (u hi, v lo)
    move.l d5,d1
    sub.l d4,d1

    move.l d1,d0
    swap d1
    muls.w d2,d1
    move.l d1,d3
    move.l d0,d1
    muls.w d2,d1

    move.l d3,d2
    swap d1
    move.w d1,d2
    move.l d2,32(sp)

    move.l d6,d2
    move.l d4,d1

    ; odd start pixel
    move.l a6,d0
    and.l #1,d0
    beq .odd_start_done

    ; tile index = (v>>16)<<8 | (u>>24)
    move.l d1,d3
    swap d3
    lsr.w #8,d3
    move.l d1,d0
    and.l #$0000FF00,d0
    or.w d3,d0
    moveq #0,d3
    move.b (a4,d0.l),d3
    tst.b d3
    beq .gta_odd_skip

    ; color from lightmap + (g<<8 | tile_idx)
    move.l d2,d0
    move.b d3,d0
    move.b (a3,d0.l),d3
    move.b d3,(a6)

.gta_odd_skip:
    addq.l #1,a6
    add.l 32(sp),d1

    ; half step for g
    move.l 36(sp),d0
    asr.l #1,d0
    add.l d0,d2
    subq.l #1,40(sp)

.odd_start_done:
    ; odd tail pixel, sample at Rt-dtdx
    move.l 40(sp),d0
    and.l #1,d0
    beq .tail_done

    move.l d5,d3
    sub.l 32(sp),d3

    move.l d3,d0
    swap d0
    lsr.w #8,d0
    and.l #$0000FF00,d3
    or.w d0,d3
    moveq #0,d0
    move.b (a4,d3.l),d0
    tst.b d0
    beq .tail_done

    ; lightmap, write at ptr[width-1]
    move.l d7,d3
    move.b d0,d3
    move.b (a3,d3.l),d0
    move.l 40(sp),d3
    subq.l #1,d3
    move.b d0,(a6,d3.l)

.tail_done:
    ; 2-pixel loop, d4=counter d5=dtdx*2 d6=dgdx
    move.l d4,60(sp)
    move.l d5,56(sp)
    move.l d6,64(sp)

    move.l 40(sp),d4
    lsr.l #1,d4
    beq .span_done
    subq.l #1,d4

    move.l 32(sp),d5
    asl.l #1,d5
    move.l 36(sp),d6

.pix2_loop:
    move.l d1,d3
    swap d3
    lsr.w #8,d3
    move.l d1,d0
    and.l #$0000FF00,d0
    or.w d3,d0
    moveq #0,d3
    move.b (a4,d0.l),d3

    addq.l #2,a6
    add.l d5,d1
    tst.b d3
    beq .gta_pix2_skip

    ; lightmap, write both bytes
    move.l d2,d0
    move.b d3,d0
    move.b (a3,d0.l),d3
    move.b d3,-2(a6)
    move.b d3,-1(a6)

.gta_pix2_skip:
    add.l d6,d2
    dbra d4,.pix2_loop

.span_done:
    move.l 60(sp),d4
    move.l 56(sp),d5
    move.l 64(sp),d6

.scanline_skip:
    lea 320(a0),a0

    move.l 0(sp),d0
    add.l d0,24(sp)
    move.l 4(sp),d0
    add.l d0,28(sp)
    add.l 16(sp),d6
    add.l 20(sp),d7
    add.l 8(sp),d4
    add.l 12(sp),d5

    subq.l #1,44(sp)
    bpl .scanline_loop

    move.l 24(sp),d2
    move.l 28(sp),d3
    move.l 52(sp),d0
    move.l 48(sp),d1
    bra .outer_loop

.return:
    add.l #72,sp
    movem.l (sp)+,d2-d7/a2-a6
    rts
