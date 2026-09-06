;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _rasterizeLineH_asm
    XDEF rasterizeLineH_asm
    XDEF _rasterizeLineV_asm
    XDEF rasterizeLineV_asm
    XDEF _rasterizeFillS_asm
    XDEF rasterizeFillS_asm

_rasterizeLineH_asm:
rasterizeLineH_asm:
    movem.l d2/a2,-(sp)

    lea 16(a2),a2

    ; x from L, color from L->g, width from R->x
    move.w 0(a1),d0
    ext.l d0

    moveq #0,d1
    move.b 6(a1),d1

    move.w 0(a2),d2
    ext.l d2

    lea (a0,d0.l),a0

    ; odd start byte
    move.l a0,d0
    and.l #1,d0
    beq .lh_odd_done

    move.b d1,(a0)+
    subq.l #1,d2
.lh_odd_done:

    ; Odd tail byte
    btst #0,d2
    beq .lh_tail_done

    subq.l #1,d2
    move.b d1,(a0,d2.l)

.lh_tail_done:

    ; replicate color to both bytes
    move.l d1,d0
    lsl.l #8,d0
    or.l d0,d1

    ; word fill
    lsr.l #1,d2
    beq .lh_done

    subq.l #1,d2

.lh_loop:
    move.w d1,(a0)+
    dbra d2,.lh_loop

.lh_done:
    movem.l (sp)+,d2/a2
    rts


    ; void rasterizeLineV_asm(uint16* pixel, const VertexLink* L, const VertexLink* R)
_rasterizeLineV_asm:
rasterizeLineV_asm:
    movem.l d2/a2,-(sp)

    lea 16(a2),a2

    ; x from L, color from L->g, height from R->y
    move.w 0(a1),d0
    ext.l d0

    moveq #0,d1
    move.b 6(a1),d1

    move.w 2(a2),d2
    ext.l d2

    lea (a0,d0.l),a0

    tst.l d2
    ble .lv_done

    subq.l #1,d2

.lv_loop:
    move.b d1,(a0)
    lea 320(a0),a0
    dbra d2,.lv_loop

.lv_done:
    movem.l (sp)+,d2/a2
    rts


    ; void rasterizeFillS_asm(uint16* pixel, const VertexLink* L, const VertexLink* R)
    ; fill rect with per-pixel lightmap shadow
_rasterizeFillS_asm:
rasterizeFillS_asm:
    movem.l d2-d5/a2-a3,-(sp)

    lea 16(a2),a2

    ; x from L, shade from L->g, width from R->x, height from R->y
    move.w 0(a1),d0
    ext.l d0

    moveq #0,d1
    move.b 6(a1),d1

    move.w 0(a2),d2
    ext.l d2

    move.w 2(a2),d3
    ext.l d3

    ; lm = &gLightmap[shade << 8]
    move.l _gLightmap,a3
    lsl.l #8,d1
    lea (a3,d1.l),a3

    lea (a0,d0.l),a0

    tst.l d3
    ble .fs_done

.fs_row_loop:
    move.l a0,a2
    move.l d2,d4

    tst.l d4
    ble .fs_row_skip

    moveq #0,d5
    subq.l #1,d4

.fs_col_loop:
    ; per-pixel: *ptr = lm[*ptr]
    move.b (a2),d5
    move.b (a3,d5.l),d5
    move.b d5,(a2)+

    dbra d4,.fs_col_loop

.fs_row_skip:
    ; next row
    lea 320(a0),a0

    subq.l #1,d3
    bne .fs_row_loop

.fs_done:
    movem.l (sp)+,d2-d5/a2-a3
    rts
