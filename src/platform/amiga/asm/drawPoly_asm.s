;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _drawPoly_asm
    XDEF drawPoly_asm

    XREF _rasterize_c

; VertexLink layout (16 bytes)
; Vertex v: x@0, y@2, z@4, g@6, clip@7
; TexCoord t: uv.v@8, uv.u@10  (union { struct{ uint16 v, u } uv; uint32 t })
; int8 prev@12, int8 next@13, uint16 padding@14
VL_X = 0
VL_Y = 2
VL_Z = 4
VL_G = 6
VL_CLIP = 7
VL_V = 8
VL_U = 10
VL_PREV = 12
VL_NEXT = 13
VL_SZ = 16

FW = 320
FH = 200
LSHIFT = 6

FACE_TRIANGLE = $80000

; Stack frame
TMP = 0
OUT = 128
D6_SAVE = 256
D7_SAVE = 260
T_SAVE = 264
FRAMESZ = 268

; void drawPoly_asm(uint32 flags, VertexLink* v)
; d0 = flags, a0 = v
_drawPoly_asm:
drawPoly_asm:
    movem.l d2-d7/a2-a6,-(sp)
    lea (-FRAMESZ,sp),sp

    ; triangle or quad?
    moveq #3,d2
    btst #19,d0
    bne.s .pcount_set
    moveq #4,d2

.pcount_set:
    ; clip left/right (axis=x)
    moveq #0,d1
    moveq #0,d3
    move.l #FW,d4
    sub.l a6,a6
    lea (TMP,sp),a4
    bsr .clip_xy

    ; need 3+ vertices after clipping
    cmp.l #3,d1
    blt .dp_ret

    ; clip top/bottom (axis=y)
    move.l d1,d2
    moveq #0,d1
    moveq #0,d3
    move.l #FH,d4
    addq.l #2,a6
    lea (TMP,sp),a0
    lea (OUT,sp),a4
    bsr .clip_xy

    cmp.l #3,d1
    blt .dp_ret

    ; first=out[0], last=out[count-1]
    move.l d1,d7
    subq.l #1,d7

    lea (OUT,sp),a0
    move.l d7,d6
    asl.l #4,d6
    lea (a0,d6.l),a2

    ; degenerate if first.y == last.y
    move.w VL_Y(a0),d3
    move.w VL_Y(a2),d4
    moveq #0,d5
    cmp.w d4,d3
    bne.s .skip_zero
    moveq #1,d5

.skip_zero:
    ; topmost vertex = rasterizer entry
    move.l a0,a3
    cmp.w d4,d3
    blt.s .top_set
    move.l a2,a3

.top_set:
    ; preload -1 and 1 for prev/next
    moveq #-1,d4
    moveq #1,d2

    ; first: prev = count-1, next = 1
    move.b d7,VL_PREV(a0)
    move.b d2,VL_NEXT(a0)

    ; last: prev = -1, next = 1-count
    move.b d4,VL_PREV(a2)
    moveq #1,d6
    sub.l d1,d6
    move.b d6,VL_NEXT(a2)

    ; Middle vertices get single-step links
    moveq #1,d6

.top_loop:
    cmp.l d7,d6
    bge.s .top_done

    move.l d6,d3
    asl.l #4,d3
    lea (a0,d3.l),a5

    ; track lowest y as top
    move.w VL_Y(a5),d3
    cmp.w VL_Y(a3),d3
    beq.s .top_same

    ; lower y becomes new top
    bge.s .top_not_lower
    move.l a5,a3

.top_not_lower:
    ; different y: not degenerate
    moveq #0,d5

.top_same:
    move.b d4,VL_PREV(a5)
    move.b d2,VL_NEXT(a5)

    addq.l #1,d6
    bra.s .top_loop

.top_done:
    ; bail if all vertices share y
    tst.l d5
    bne.s .dp_ret

    ; call rasterizer
    movem.l d0/a3,-(sp)
    jsr _rasterize_c
    addq.l #8,sp

.dp_ret:
    lea (FRAMESZ,sp),sp
    movem.l (sp)+,d2-d7/a2-a6
    rts


; Clip polygon against one axis, a6 = word offset (0=x, 2=y)
; d3/d4 = min/max bounds, d2 = input count, d1 = output count
.clip_xy:
    ; start from last vertex, each edge is (prev, current)
    move.l d2,d7
    subq.l #1,d7
    asl.l #4,d7
    lea (a0,d7.l),a5
    move.l d2,d7
    moveq #0,d6

.cp_loop:
    move.l a5,a3
    move.l d6,d5
    asl.l #4,d5
    lea (a0,d5.l),a5

    ; classify a against clip window
    move.w (a3,a6.l),d5
    cmp.w d3,d5
    blt.s .cp_a_below
    cmp.w d4,d5
    bgt.s .cp_a_above
    bra.s .cp_check_b

.cp_a_below:
    ; a below min: intersection only if b inside
    move.w (a5,a6.l),d5
    cmp.w d3,d5
    blt.s .cp_next
    move.l d3,a1
    bsr .clip_axis
    bra.s .cp_check_b

.cp_a_above:
    ; a above max: intersection only if b inside
    move.w (a5,a6.l),d5
    cmp.w d4,d5
    bgt.s .cp_next
    move.l d4,a1
    bsr .clip_axis

.cp_check_b:
    ; b inside: copy straight through
    move.w (a5,a6.l),d5
    cmp.w d3,d5
    blt.s .cp_b_below
    cmp.w d4,d5
    bgt.s .cp_b_above

    move.l d1,d5
    asl.l #4,d5
    lea (a4,d5.l),a2
    move.l (a5),(a2)
    move.l 4(a5),4(a2)
    move.l 8(a5),8(a2)
    move.l 12(a5),12(a2)
    addq.l #1,d1
    bra.s .cp_next

.cp_b_below:
    move.l d3,a1
    bsr .clip_axis
    bra.s .cp_next

.cp_b_above:
    move.l d4,a1
    bsr .clip_axis

.cp_next:
    addq.l #1,d6
    subq.l #1,d7
    bne.s .cp_loop
    rts


; interpolate vertex where edge (a,b) crosses clip plane
; a=a3, b=a5, edge value=a1, axis word=a6, output=a4, count=d1
.clip_axis:
    move.l d6,D6_SAVE(sp)
    move.l d7,D7_SAVE(sp)

    ; reserve slot for new vertex
    move.l d1,d5
    asl.l #4,d5
    lea (a4,d5.l),a2
    addq.l #1,d1

    ; ta=(edge-b)<<6, tb=a-b, along clip axis
    move.w (a5,a6.l),d7
    ext.l d7
    move.l a1,d5
    sub.l d7,d5
    asl.l #LSHIFT,d5

    move.w (a3,a6.l),d6
    ext.l d6
    sub.l d7,d6

    ; t = ta/tb
    move.l d5,d2
    divs.l d6,d2
    move.l d2,T_SAVE(sp)

    ; new vertex on the clip plane
    move.w a1,(a2,a6.l)

    ; perpendicular axis (cross = 2 - axis)
    moveq #2,d7
    sub.l a6,d7
    move.w (a3,d7.l),d2
    ext.l d2
    move.w (a5,d7.l),a1
    sub.l a1,d2
    muls.l d5,d2
    divs.l d6,d2
    asr.l #LSHIFT,d2
    add.l a1,d2
    move.w d2,(a2,d7.l)

    ; Interpolate g by t
    clr.l d2
    move.b VL_G(a3),d2
    clr.l d7
    move.b VL_G(a5),d7
    sub.l d7,d2
    move.l T_SAVE(sp),d5
    muls.l d5,d2
    asr.l #LSHIFT,d2
    add.l d7,d2
    move.b d2,VL_G(a2)

    ; Interpolate u by t
    clr.l d2
    move.w VL_U(a3),d2
    clr.l d7
    move.w VL_U(a5),d7
    sub.l d7,d2
    muls.l d5,d2
    asr.l #LSHIFT,d2
    add.l d7,d2
    move.w d2,VL_U(a2)

    ; Interpolate v by t
    clr.l d2
    move.w VL_V(a3),d2
    clr.l d7
    move.w VL_V(a5),d7
    sub.l d7,d2
    muls.l d5,d2
    asr.l #LSHIFT,d2
    add.l d7,d2
    move.w d2,VL_V(a2)

    move.l D6_SAVE(sp),d6
    move.l D7_SAVE(sp),d7
    rts
