;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _matrixPush_asm
    XDEF matrixPush_asm
    XDEF _matrixSetIdentity_asm
    XDEF matrixSetIdentity_asm
    XDEF _matrixSetBasis_asm
    XDEF matrixSetBasis_asm
    XDEF _matrixLerp_asm
    XDEF matrixLerp_asm
    XDEF _matrixTranslateRel_asm
    XDEF matrixTranslateRel_asm
    XDEF _matrixTranslateAbs_asm
    XDEF matrixTranslateAbs_asm
    XDEF _matrixTranslateSet_asm
    XDEF matrixTranslateSet_asm
    XDEF _matrixRotateX_asm
    XDEF matrixRotateX_asm
    XDEF _matrixRotateY_asm
    XDEF matrixRotateY_asm
    XDEF _matrixRotateZ_asm
    XDEF matrixRotateZ_asm
    XDEF _matrixRotateYXZ_asm
    XDEF matrixRotateYXZ_asm
    XDEF _matrixFrame_asm
    XDEF matrixFrame_asm
    XDEF _matrixRotateYQ_asm
    XDEF matrixRotateYQ_asm
    XDEF _boxTranslate_asm
    XDEF boxTranslate_asm
    XDEF _boxRotateYQ_asm
    XDEF boxRotateYQ_asm
    XDEF _sphereIsVisible_asm
    XDEF sphereIsVisible_asm

    XREF _divTable
    XREF _gCameraViewPos
    XREF _gSinCosTable
    XREF _gMatrixPtr
    XREF _viewport

; void matrixPush_asm()
; copy current matrix to next slot, advance gMatrixPtr
_matrixPush_asm:
matrixPush_asm:
    move.l _gMatrixPtr,a0
    movem.l (a0)+,d0-d5
    movem.l d0-d5,(a0)
    move.l a0,_gMatrixPtr
    rts

; void matrixSetIdentity_asm()
; set current matrix to identity (0x4000 diagonal)
_matrixSetIdentity_asm:
matrixSetIdentity_asm:
    move.l _gMatrixPtr,a0
    move.l #$40000000,d0
    move.l d0,(a0)+
    clr.l (a0)+
    move.l d0,(a0)+
    clr.l (a0)+
    move.l d0,(a0)+
    clr.l (a0)
    rts

; void matrixSetBasis_asm(Matrix &dst, const Matrix &src)
; a0=dst, a1=src
; copy rotation basis (e00-e12, 3 longs)
_matrixSetBasis_asm:
matrixSetBasis_asm:
    move.l (a1)+,(a0)+
    move.l (a1)+,(a0)+
    move.l (a1)+,(a0)
    rts

; void matrixLerp_asm(const Matrix &n, int32 pmul, int32 pdiv)
; a0=&n, d0=pmul, d1=pdiv
; lerp current matrix towards n by pmul/pdiv
_matrixLerp_asm:
matrixLerp_asm:
    movem.l d2-d6/a2,-(sp)
    move.l _gMatrixPtr,a1

    ; common ratio fast paths
    cmp.l #2,d1
    beq .lerp_1_2
    cmp.l #4,d1
    bne .lerp_slow
    cmp.l #1,d0
    beq .lerp_1_4
    cmp.l #2,d0
    beq .lerp_1_2

; a = b - ((b - a) >> 2)  (3/4 towards b)
.lerp_3_4:
    moveq #11,d6

.l3_loop:
    move.w (a1),d2
    move.w (a0)+,d3
    ext.l d2
    ext.l d3
    move.l d3,d4
    sub.l d2,d3
    asr.l #2,d3
    sub.l d3,d4
    move.w d4,(a1)+
    dbra d6,.l3_loop
    bra .lerp_done

; a = (b + a) >> 1  (midpoint)
.lerp_1_2:
    moveq #11,d6

.l12_loop:
    move.w (a1),d2
    move.w (a0)+,d3
    ext.l d2
    ext.l d3
    add.l d3,d2
    asr.l #1,d2
    move.w d2,(a1)+
    dbra d6,.l12_loop
    bra .lerp_done

; a = a + ((b - a) >> 2)  (1/4 towards b)
.lerp_1_4:
    moveq #11,d6

.l14_loop:
    move.w (a1),d2
    move.w (a0)+,d3
    ext.l d2
    ext.l d3
    sub.l d2,d3
    asr.l #2,d3
    add.l d3,d2
    move.w d2,(a1)+
    dbra d6,.l14_loop
    bra .lerp_done

; general case: t = pmul * (1/pdiv) >> 8
.lerp_slow:
    lea _divTable,a2
    moveq #0,d4
    move.w (a2,d1.w*2),d4
    muls.l d0,d4
    asr.l #8,d4
    moveq #11,d6

.ls_loop:
    move.w (a1),d2
    move.w (a0)+,d3
    ext.l d2
    ext.l d3
    sub.l d2,d3
    muls.l d4,d3
    asr.l #8,d3
    add.l d3,d2
    move.w d2,(a1)+
    dbra d6,.ls_loop

.lerp_done:
    movem.l (sp)+,d2-d6/a2
    rts

; dot product of 3x3 rotation with (x,y,z), >>14
; d0=x, d1=y, d2=z, a0=matrix
; out: d3=tx, d4=ty, d5=tz, clobbers d7, a0 past e03
dp33_shift_helper:
    ; Row 0
    move.w (a0)+,d3
    ext.l d3
    muls.l d0,d3
    move.w (a0)+,d7
    ext.l d7
    muls.l d1,d7
    add.l d7,d3
    move.w (a0)+,d7
    ext.l d7
    muls.l d2,d7
    add.l d7,d3
    asr.l #8,d3
    asr.l #6,d3

    ; Row 1
    move.w (a0)+,d4
    ext.l d4
    muls.l d0,d4
    move.w (a0)+,d7
    ext.l d7
    muls.l d1,d7
    add.l d7,d4
    move.w (a0)+,d7
    ext.l d7
    muls.l d2,d7
    add.l d7,d4
    asr.l #8,d4
    asr.l #6,d4

    ; Row 2
    move.w (a0)+,d5
    ext.l d5
    muls.l d0,d5
    move.w (a0)+,d7
    ext.l d7
    muls.l d1,d7
    add.l d7,d5
    move.w (a0)+,d7
    ext.l d7
    muls.l d2,d7
    add.l d7,d5
    asr.l #8,d5
    asr.l #6,d5
    rts

; void matrixTranslateRel_asm(int32 x, int32 y, int32 z)
; d0=x, d1=y, d2=z
; m.e03 += DP33(x,y,z) >> 14
_matrixTranslateRel_asm:
matrixTranslateRel_asm:
    movem.l d3-d5/d7,-(sp)
    move.l _gMatrixPtr,a0
    bsr dp33_shift_helper

    add.w d3,(a0)+
    add.w d4,(a0)+
    add.w d5,(a0)

    movem.l (sp)+,d3-d5/d7
    rts

; void matrixTranslateSet_asm(int32 x, int32 y, int32 z)
; d0=x, d1=y, d2=z
; m.e03 = DP33(x,y,z) >> 14
_matrixTranslateSet_asm:
matrixTranslateSet_asm:
    movem.l d3-d5/d7,-(sp)
    move.l _gMatrixPtr,a0
    bsr dp33_shift_helper

    move.w d3,(a0)+
    move.w d4,(a0)+
    move.w d5,(a0)

    movem.l (sp)+,d3-d5/d7
    rts

; void matrixTranslateAbs_asm(int32 x, int32 y, int32 z)
; d0=x, d1=y, d2=z
; subtract camera pos, then m.e03 = DP33 >> 14
_matrixTranslateAbs_asm:
matrixTranslateAbs_asm:
    movem.l d2-d5/d7,-(sp)
    sub.l _gCameraViewPos,d0
    sub.l _gCameraViewPos+4,d1
    sub.l _gCameraViewPos+8,d2
    move.l _gMatrixPtr,a0
    bsr dp33_shift_helper

    move.w d3,(a0)+
    move.w d4,(a0)+
    move.w d5,(a0)

    movem.l (sp)+,d2-d5/d7
    rts

; sincos(angle d0) -> d1=c, d2=s
; clobbers d1, d2, d3
sincos_helper:
    moveq #0,d3
    move.w d0,d3
    lsr.w #4,d3
    move.l _gSinCosTable(d3.l*4),d1
    move.l d1,d2
    swap d2
    ext.l d2
    ext.l d1
    rts

; rot_xy: a1=&x, a2=&y, d1=c, d2=s
; x' = (x*c - y*s) >> 14, y' = (y*c + x*s) >> 14
rot_xy:
    move.w (a1),d3
    move.w (a2),d4
    move.w d3,d5
    muls.w d1,d5
    muls.w d2,d3
    move.w d4,d6
    muls.w d2,d6
    sub.l d6,d5
    asr.l #8,d5
    asr.l #6,d5
    muls.w d1,d4
    add.l d3,d4
    asr.l #8,d4
    asr.l #6,d4
    move.w d5,(a1)
    move.w d4,(a2)
    rts

; void matrixRotateY_asm(int32 angle)
; d0 = angle
; rotate cols 0,2: (e00,e02) (e10,e12) (e20,e22)
_matrixRotateY_asm:
matrixRotateY_asm:
    movem.l d2-d6/a2,-(sp)
    bsr sincos_helper
    move.l _gMatrixPtr,a0
    move.l a0,a1
    lea 4(a0),a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    movem.l (sp)+,d2-d6/a2
    rts

; void matrixRotateX_asm(int32 angle)
; d0 = angle
; rotate cols 1,2: (e02,e01) (e12,e11) (e22,e21)
_matrixRotateX_asm:
matrixRotateX_asm:
    movem.l d2-d6/a2,-(sp)
    bsr sincos_helper
    move.l _gMatrixPtr,a0
    lea 4(a0),a1
    lea 2(a0),a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    movem.l (sp)+,d2-d6/a2
    rts

; void matrixRotateZ_asm(int32 angle)
; d0 = angle
; rotate cols 0,1: (e01,e00) (e11,e10) (e21,e20)
_matrixRotateZ_asm:
matrixRotateZ_asm:
    movem.l d2-d6/a2,-(sp)
    bsr sincos_helper
    move.l _gMatrixPtr,a0
    lea 2(a0),a1
    move.l a0,a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    addq.l #6,a1
    addq.l #6,a2
    bsr rot_xy
    movem.l (sp)+,d2-d6/a2
    rts

; void matrixRotateYXZ_asm(int32 angleX, int32 angleY, int32 angleZ)
; d0=angleX, d1=angleY, d2=angleZ
; conditional Y,X,Z rotation (skip if angle=0)
_matrixRotateYXZ_asm:
matrixRotateYXZ_asm:
    move.l d3,-(sp)
    move.l d4,-(sp)
    move.l d0,d3
    move.l d2,d4

    move.l d1,d0
    beq .skipY
    bsr matrixRotateY_asm

.skipY:
    move.l d3,d0
    beq .skipX
    bsr matrixRotateX_asm

.skipX:
    move.l d4,d0
    beq .skipZ
    bsr matrixRotateZ_asm

.skipZ:
    move.l (sp)+,d4
    move.l (sp)+,d3
    rts

; void matrixFrame_asm(const void* pos, const void* angles)
; a0=pos, a1=angles
; decode angles, read pos, translate then rotate YXZ
_matrixFrame_asm:
matrixFrame_asm:
    movem.l d2-d4/a2,-(sp)

    ; DECODE_ANGLES from packed uint32
    move.l (a1),d4

    ; aX = (a & 0x3FF0) << 2
    move.w d4,d2
    and.w #$3FF0,d2
    lsl.w #2,d2

    ; Get hi word once for aZ and aY
    move.l d4,d3
    swap d3

    ; aZ = (hi & 0x03FF) << 6
    move.w d3,d0
    and.w #$03FF,d3
    lsl.w #6,d3

    ; aY = (lo & 0x000F) << 12 | (hi & 0xFC00) >> 4
    move.w d4,d1
    and.w #$000F,d1
    moveq #12,d4
    lsl.w d4,d1
    and.w #$FC00,d0
    lsr.w #4,d0
    or.w d0,d1

    ; Save decoded angles
    move.l d2,-(sp)
    move.l d1,-(sp)
    move.l d3,-(sp)

    ; read pos (big endian): posX=hi(xy) posY=lo(xy) posZ=hi(zu)
    move.l (a0)+,d0
    move.l (a0),d4

    ; d2 = posZ = hi word of zu
    move.l d4,d2
    swap d2
    ext.l d2

    ; d1 = posY = lo word of xy
    move.w d0,d1
    ext.l d1

    ; d0 = posX = hi word of xy
    swap d0
    ext.l d0

    bsr _matrixTranslateRel_asm

    ; Restore angles and call rotateYXZ
    move.l (sp)+,d2
    move.l (sp)+,d1
    move.l (sp)+,d0
    ext.l d0
    ext.l d1
    ext.l d2
    bsr _matrixRotateYXZ_asm

    movem.l (sp)+,d2-d4/a2
    rts

; void matrixRotateYQ_asm(int32 quadrant)
; d0 = quadrant
; 90-deg Y rotation by quadrant (0=neg, 1=swap, 2=noop, 3=swap+neg)
_matrixRotateYQ_asm:
matrixRotateYQ_asm:
    cmp.l #2,d0
    beq .yq_done

    move.l _gMatrixPtr,a0

    ; q==0: negate columns 0 and 2
    cmp.l #0,d0
    bne .yq_not0

    neg.w 0(a0)
    neg.w 6(a0)
    neg.w 12(a0)
    neg.w 4(a0)
    neg.w 10(a0)
    neg.w 16(a0)
    bra .yq_done

; q==1: col2 = -col0, col0 = old col2
.yq_not0:
    move.w 4(a0),d1
    move.w 10(a0),d2
    move.w 16(a0),d3

    cmp.l #1,d0
    bne .yq_q3

    move.w 0(a0),d4
    neg.w d4
    move.w d4,4(a0)
    move.w 6(a0),d4
    neg.w d4
    move.w d4,10(a0)
    move.w 12(a0),d4
    neg.w d4
    move.w d4,16(a0)

    move.w d1,0(a0)
    move.w d2,6(a0)
    move.w d3,12(a0)
    bra .yq_done

; q==3: col2 = col0, col0 = -old col2
.yq_q3:
    move.w 0(a0),d4
    move.w d4,4(a0)
    move.w 6(a0),d4
    move.w d4,10(a0)
    move.w 12(a0),d4
    move.w d4,16(a0)

    neg.w d1
    neg.w d2
    neg.w d3
    move.w d1,0(a0)
    move.w d2,6(a0)
    move.w d3,12(a0)

.yq_done:
    rts

; void boxTranslate_asm(AABBi &box, int32 x, int32 y, int32 z)
; a0=box, d0=x, d1=y, d2=z
; AABBi: minX=0, maxX=4, minY=8, maxY=12, minZ=16, maxZ=20
_boxTranslate_asm:
boxTranslate_asm:
    add.l d0,0(a0)
    add.l d0,4(a0)
    add.l d1,8(a0)
    add.l d1,12(a0)
    add.l d2,16(a0)
    add.l d2,20(a0)
    rts

; void boxRotateYQ_asm(AABBi &box, int32 quadrant)
; a0=box, d0=quadrant
; rotate X/Z bounds by 90-degree steps
_boxRotateYQ_asm:
boxRotateYQ_asm:
    cmp.l #2,d0
    beq .brq_done

    move.l 0(a0),d1
    move.l 4(a0),d2
    move.l 16(a0),d3
    move.l 20(a0),d4

    ; q==3: X=Z, Z=-X
    cmp.l #3,d0
    bne .brq_not3

    move.l d3,0(a0)
    move.l d4,4(a0)
    neg.l d2
    move.l d2,16(a0)
    neg.l d1
    move.l d1,20(a0)
    bra .brq_done

; q==1: X=-Z, Z=X
.brq_not3:
    cmp.l #1,d0
    bne .brq_not1

    neg.l d4
    move.l d4,0(a0)
    neg.l d3
    move.l d3,4(a0)
    move.l d1,16(a0)
    move.l d2,20(a0)
    bra .brq_done

; q==0: negate X and Z
.brq_not1:
    neg.l d2
    move.l d2,0(a0)
    neg.l d1
    move.l d1,4(a0)
    neg.l d4
    move.l d4,16(a0)
    neg.l d3
    move.l d3,20(a0)

.brq_done:
    rts

; int32 sphereIsVisible_asm(int32 x, int32 y, int32 z, int32 r)
; d0=x, d1=y, d2=z, d3=r
; returns d0=1 visible, 0 otherwise
_sphereIsVisible_asm:
sphereIsVisible_asm:
    movem.l d2-d7/a2-a3,-(sp)

    ; fast path: all coords within radius = visible
    move.l d0,d4
    bpl .x_pos
    neg.l d4

.x_pos:
    cmp.l d3,d4
    bge .no_fast

    move.l d1,d4
    bpl .y_pos
    neg.l d4

.y_pos:
    cmp.l d3,d4
    bge .no_fast

    move.l d2,d4
    bpl .z_pos
    neg.l d4

.z_pos:
    cmp.l d3,d4
    bge .no_fast

    moveq #1,d0
    bra .siv_done

.no_fast:
    move.l _gMatrixPtr,a0

    ; transform center through matrix
    ; z = DP33(row2, x, y, z)
    move.w 12(a0),d4
    ext.l d4
    muls.l d0,d4
    move.w 14(a0),d5
    ext.l d5
    muls.l d1,d5
    add.l d5,d4
    move.w 16(a0),d5
    ext.l d5
    muls.l d2,d5
    add.l d5,d4

    ; behind camera?
    tst.l d4
    bmi .siv_notvis

    ; x = DP33(row0, x, y, z)
    move.w 0(a0),d5
    ext.l d5
    muls.l d0,d5
    move.w 2(a0),d6
    ext.l d6
    muls.l d1,d6
    add.l d6,d5
    move.w 4(a0),d6
    ext.l d6
    muls.l d2,d6
    add.l d6,d5

    ; y = DP33(row1, x, y, z)
    move.w 6(a0),d6
    ext.l d6
    muls.l d0,d6
    move.w 8(a0),d7
    ext.l d7
    muls.l d1,d7
    add.l d7,d6
    move.w 10(a0),d7
    ext.l d7
    muls.l d2,d7
    add.l d7,d6

    ; perspective divide: x,y,z >>= 14, z >>= 4
    asr.l #8,d5
    asr.l #6,d5
    asr.l #8,d6
    asr.l #6,d6
    asr.l #8,d4
    asr.l #6,d4
    asr.l #4,d4

    ; clamp z to divTable range
    cmp.l #1025,d4
    blt .z_ok
    move.l #1024,d4

.z_ok:
    ; d = 1/z
    moveq #0,d7
    move.w _divTable(d4.l*2),d7

    ; Project x, y, and r
    muls.l d7,d5
    asr.l #8,d5
    asr.l #4,d5

    muls.l d7,d3
    asr.l #8,d3
    asr.l #4,d3

    muls.l d7,d6
    asr.l #8,d6
    asr.l #4,d6

    ; center on screen
    add.l #160,d5
    add.l #100,d6

    ; bbox vs viewport
    ; Left edge
    move.l d5,d0
    sub.l d3,d0
    cmp.l _viewport+8,d0
    bgt .siv_notvis

    ; Right edge
    move.l d5,d4
    add.l d3,d4
    cmp.l _viewport,d4
    blt .siv_notvis

    ; Top edge
    move.l d6,d0
    sub.l d3,d0
    cmp.l _viewport+12,d0
    bgt .siv_notvis

    ; Bottom edge
    move.l d6,d4
    add.l d3,d4
    cmp.l _viewport+4,d4
    blt .siv_notvis

    moveq #1,d0
    bra .siv_done

.siv_notvis:
    moveq #0,d0

.siv_done:
    movem.l (sp)+,d2-d7/a2-a3
    rts
