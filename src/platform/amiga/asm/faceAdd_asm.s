;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _faceAddRoomQuads_asm
    XDEF faceAddRoomQuads_asm
    XDEF _faceAddRoomTriangles_asm
    XDEF faceAddRoomTriangles_asm
    XDEF _faceAddMeshQuads_asm
    XDEF faceAddMeshQuads_asm
    XDEF _faceAddMeshTriangles_asm
    XDEF faceAddMeshTriangles_asm

    XREF _gVerticesBase
    XREF _gVertices
    XREF _gFacesBase
    XREF _gOT

VX_X = 0
VX_Y = 2
VX_Z = 4
VX_G = 6
VX_CLIP = 7

FC_FLAGS = 0
FC_NEXT = 4
FC_IDX0 = 8
FC_IDX1 = 10
FC_IDX2 = 12
FC_IDX3 = 14
FC_SIZE = 16

RQ_I0 = 0
RQ_I1 = 1
RQ_I2 = 2
RQ_I3 = 3
RQ_FLAGS = 4
RQ_SIZE = 8

RT_I0 = 0
RT_I1 = 2
RT_I2 = 4
RT_FLAGS = 6
RT_SIZE = 8

MQ_I0 = 0
MQ_I1 = 1
MQ_I2 = 2
MQ_I3 = 3
MQ_FLAGS = 4
MQ_SIZE = 8

MT_I0 = 0
MT_I1 = 1
MT_I3 = 3
MT_FLAGS = 4
MT_SIZE = 8

CLIP_DISCARD = $1F
CLIP_FRAME = $20
FACE_CLIPPED = $40000
FACE_GOURAUD = $8000
FACE_TRIANGLE = $80000
OT_SHIFT = 4

; void faceAddRoomQuads_asm(const RoomQuad* polys, int32 count)
; a0=polys, d0=count
_faceAddRoomQuads_asm:
faceAddRoomQuads_asm:
    movem.l d2-d7/a2-a6,-(sp)
    move.l a0,a4
    move.l d0,d6
    move.l _gVerticesBase,a3
    lea _gOT,a5
    move.l #_gVertices,d5
    move.l _gFacesBase,a6

    subq.l #1,d6
    blt .rq_ret

.rq_loop:
    moveq #0,d7
    move.w RQ_FLAGS(a4),d7

    ; vertex indices
    move.b RQ_I0(a4),d0
    extb.l d0
    lea (a3,d0.l*8),a2

    move.b RQ_I1(a4),d0
    extb.l d0
    lea (a2,d0.l*8),a1

    move.b RQ_I2(a4),d0
    extb.l d0
    lea (a1,d0.l*8),a0

    move.b RQ_I3(a4),d0
    extb.l d0
    lea (a0,d0.l*8),a3

    ; discard if all clipped
    move.b VX_CLIP(a2),d1
    move.b VX_CLIP(a1),d2
    move.b VX_CLIP(a0),d3
    move.b VX_CLIP(a3),d4

    move.b d1,d0
    and.b d2,d0
    and.b d3,d0
    and.b d4,d0
    and.b #CLIP_DISCARD,d0
    bne .rq_next

    ; frame flag if any vertex touches border
    move.b d1,d0
    or.b d2,d0
    or.b d3,d0
    or.b d4,d0
    btst #5,d0
    beq .rq_no_frame
    bset #18,d7

.rq_no_frame:
    ; backface cull (signed area)
    move.w VX_X(a2),d1
    ext.l d1
    move.w VX_Y(a2),d2
    ext.l d2

    move.w VX_X(a1),d3
    ext.l d3
    sub.l d1,d3

    move.w VX_Y(a0),d4
    ext.l d4
    sub.l d2,d4
    muls.l d3,d4

    move.w VX_X(a0),d0
    ext.l d0
    sub.l d1,d0

    move.w VX_Y(a1),d1
    ext.l d1
    sub.l d2,d1
    muls.l d0,d1

    cmp.l d1,d4
    ble .rq_next

    ; gouraud if shades differ
    move.b VX_G(a2),d0
    move.b VX_G(a1),d1
    cmp.b d0,d1
    bne .rq_gouraud
    move.b VX_G(a0),d1
    cmp.b d0,d1
    bne .rq_gouraud
    move.b VX_G(a3),d1
    cmp.b d0,d1
    beq .rq_no_gouraud

.rq_gouraud:
    add.l #FACE_GOURAUD,d7

.rq_no_gouraud:
    ; depth = min z >> OT_SHIFT
    move.w VX_Z(a2),d0
    move.w VX_Z(a1),d1
    cmp.w d0,d1
    ble .rq_z1
    move.w d1,d0

.rq_z1:
    move.w VX_Z(a0),d1
    cmp.w d0,d1
    ble .rq_z2
    move.w d1,d0

.rq_z2:
    move.w VX_Z(a3),d1
    cmp.w d0,d1
    ble .rq_z3
    move.w d1,d0

.rq_z3:
    ext.l d0
    asr.l #OT_SHIFT,d0

    ; insert into OT bucket
    move.l (a5,d0.l*4),FC_NEXT(a6)
    move.l a6,(a5,d0.l*4)
    move.l d7,FC_FLAGS(a6)

    ; vertex indices (offset from gVertices)
    move.l a2,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX0(a6)

    move.l a1,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX1(a6)

    move.l a0,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX2(a6)

    move.l a3,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX3(a6)

    lea (FC_SIZE,a6),a6

.rq_next:
    addq.l #RQ_SIZE,a4
    subq.l #1,d6
    bpl .rq_loop

    move.l a6,_gFacesBase

.rq_ret:
    movem.l (sp)+,d2-d7/a2-a6
    rts

; void faceAddRoomTriangles_asm(const RoomTriangle* polys, int32 count)
; a0=polys, d0=count
_faceAddRoomTriangles_asm:
faceAddRoomTriangles_asm:
    movem.l d2-d7/a2-a6,-(sp)
    move.l a0,a4
    move.l d0,d6
    move.l _gVerticesBase,a3
    lea _gOT,a5
    move.l #_gVertices,d5
    move.l _gFacesBase,a6

    subq.l #1,d6
    blt .rt_ret

.rt_loop:
    moveq #0,d7
    move.w RT_FLAGS(a4),d7

    ; vertex indices
    moveq #0,d0
    move.w RT_I0(a4),d0
    lea (a3,d0.l*8),a2

    moveq #0,d0
    move.w RT_I1(a4),d0
    lea (a3,d0.l*8),a1

    moveq #0,d0
    move.w RT_I2(a4),d0
    lea (a3,d0.l*8),a0

    ; discard if all clipped
    move.b VX_CLIP(a2),d1
    move.b VX_CLIP(a1),d2
    move.b VX_CLIP(a0),d3

    move.b d1,d0
    and.b d2,d0
    and.b d3,d0
    and.b #CLIP_DISCARD,d0
    bne .rt_next

    ; frame flag if any vertex touches border
    move.b d1,d0
    or.b d2,d0
    or.b d3,d0
    btst #5,d0
    beq .rt_no_frame
    bset #18,d7

.rt_no_frame:
    ; backface cull (signed area)
    move.w VX_X(a2),d1
    ext.l d1
    move.w VX_Y(a2),d2
    ext.l d2

    move.w VX_X(a1),d3
    ext.l d3
    sub.l d1,d3

    move.w VX_Y(a0),d4
    ext.l d4
    sub.l d2,d4
    muls.l d3,d4

    move.w VX_X(a0),d0
    ext.l d0
    sub.l d1,d0

    move.w VX_Y(a1),d1
    ext.l d1
    sub.l d2,d1
    muls.l d0,d1

    cmp.l d1,d4
    ble .rt_next

    ; gouraud if shades differ
    move.b VX_G(a2),d0
    move.b VX_G(a1),d1
    cmp.b d0,d1
    bne .rt_gouraud
    move.b VX_G(a0),d1
    cmp.b d0,d1
    bne .rt_gouraud
    bra .rt_tri

.rt_gouraud:
    add.l #FACE_GOURAUD,d7

.rt_tri:
    ; mark as triangle
    bset #19,d7

    ; depth = min z >> OT_SHIFT
    move.w VX_Z(a2),d0
    move.w VX_Z(a1),d1
    cmp.w d0,d1
    ble .rt_z1
    move.w d1,d0

.rt_z1:
    move.w VX_Z(a0),d1
    cmp.w d0,d1
    ble .rt_z2
    move.w d1,d0

.rt_z2:
    ext.l d0
    asr.l #OT_SHIFT,d0

    ; insert into OT bucket
    move.l (a5,d0.l*4),FC_NEXT(a6)
    move.l a6,(a5,d0.l*4)
    move.l d7,FC_FLAGS(a6)

    ; vertex indices (offset from gVertices)
    move.l a2,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX0(a6)

    move.l a1,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX1(a6)

    move.l a0,d0
    sub.l d5,d0
    asr.l #3,d0
    move.w d0,FC_IDX2(a6)

    lea (FC_SIZE,a6),a6

.rt_next:
    addq.l #RT_SIZE,a4
    subq.l #1,d6
    bpl .rt_loop

    move.l a6,_gFacesBase

.rt_ret:
    movem.l (sp)+,d2-d7/a2-a6
    rts

; void faceAddMeshQuads_asm(const MeshQuad* polys, int32 count)
; a0=polys, d0=count
; mesh quads: backface first, no gouraud, depth = avg z
_faceAddMeshQuads_asm:
faceAddMeshQuads_asm:
    movem.l d2-d7/a2-a6,-(sp)
    move.l a0,a4
    move.l d0,d6
    move.l _gVerticesBase,a3
    lea _gOT,a5
    move.l #_gVertices,d5
    move.l _gFacesBase,a6

    subq.l #1,d6
    blt .mq_ret

.mq_loop:
    ; vertex indices
    move.b MQ_I0(a4),d0
    extb.l d0
    lea (a3,d0.l*8),a2

    move.b MQ_I1(a4),d0
    extb.l d0
    lea (a2,d0.l*8),a1

    move.b MQ_I2(a4),d0
    extb.l d0
    lea (a1,d0.l*8),a0

    move.b MQ_I3(a4),d0
    extb.l d0
    lea (a0,d0.l*8),a3

    ; backface cull first (mesh: no clip flags yet)
    move.w VX_X(a2),d1
    ext.l d1
    move.w VX_Y(a2),d2
    ext.l d2

    move.w VX_X(a1),d3
    ext.l d3
    sub.l d1,d3

    move.w VX_Y(a0),d4
    ext.l d4
    sub.l d2,d4
    muls.l d3,d4

    move.w VX_X(a0),d0
    ext.l d0
    sub.l d1,d0

    move.w VX_Y(a1),d1
    ext.l d1
    sub.l d2,d1
    muls.l d0,d1

    cmp.l d1,d4
    ble .mq_next

    ; discard if all clipped
    move.b VX_CLIP(a2),d1
    move.b VX_CLIP(a1),d2
    move.b VX_CLIP(a0),d3
    move.b VX_CLIP(a3),d4

    move.b d1,d0
    and.b d2,d0
    and.b d3,d0
    and.b d4,d0
    and.b #CLIP_DISCARD,d0
    bne .mq_next

    moveq #0,d7
    move.w MQ_FLAGS(a4),d7

    ; frame flag if any vertex touches border
    move.b d1,d0
    or.b d2,d0
    or.b d3,d0
    or.b d4,d0
    btst #5,d0
    beq .mq_no_frame
    bset #18,d7

.mq_no_frame:
    ; depth = (z0+z1+z2+z3) >> 6
    move.w VX_Z(a2),d0
    ext.l d0
    move.w VX_Z(a1),d1
    ext.l d1
    add.l d1,d0
    move.w VX_Z(a0),d1
    ext.l d1
    add.l d1,d0
    move.w VX_Z(a3),d1
    ext.l d1
    add.l d1,d0
    asr.l #6,d0

    ; insert into OT bucket
    move.l (a5,d0.l*4),FC_NEXT(a6)
    move.l a6,(a5,d0.l*4)
    move.l d7,FC_FLAGS(a6)

    ; vertex indices (offset from gVertices)
    move.l a2,d0
    sub.l d5,d0
    asr.l #3,d0

    move.l a1,d1
    sub.l d5,d1
    asr.l #3,d1

    move.l a0,d2
    sub.l d5,d2
    asr.l #3,d2

    move.l a3,d3
    sub.l d5,d3
    asr.l #3,d3

    movem.w d0-d3,FC_IDX0(a6)

    lea (FC_SIZE,a6),a6

.mq_next:
    addq.l #MQ_SIZE,a4
    subq.l #1,d6
    bpl .mq_loop

    move.l a6,_gFacesBase

.mq_ret:
    movem.l (sp)+,d2-d7/a2-a6
    rts

; void faceAddMeshTriangles_asm(const MeshTriangle* polys, int32 count)
; a0=polys, d0=count
; mesh tris: backface first, no gouraud, depth = (z0+z1+z2*2)>>6
_faceAddMeshTriangles_asm:
faceAddMeshTriangles_asm:
    movem.l d2-d3/d5-d7/a2-a6,-(sp)
    move.l a0,a4
    move.l d0,d6
    move.l _gVerticesBase,a3
    lea _gOT,a5
    move.l #_gVertices,d5
    move.l _gFacesBase,a6

    subq.l #1,d6
    blt .mt_ret

.mt_loop:
    ; vertex indices
    move.b MT_I0(a4),d0
    extb.l d0
    lea (a3,d0.l*8),a2

    move.b MT_I1(a4),d0
    extb.l d0
    lea (a2,d0.l*8),a1

    move.b MT_I3(a4),d0
    extb.l d0
    lea (a1,d0.l*8),a3

    ; backface cull first
    move.w VX_X(a2),d1
    ext.l d1
    move.w VX_Y(a2),d2
    ext.l d2

    move.w VX_X(a1),d3
    ext.l d3
    sub.l d1,d3

    move.w VX_Y(a3),d0
    ext.l d0
    sub.l d2,d0
    muls.l d3,d0

    move.w VX_X(a3),d3
    ext.l d3
    sub.l d1,d3

    move.w VX_Y(a1),d1
    ext.l d1
    sub.l d2,d1
    muls.l d3,d1

    cmp.l d1,d0
    ble .mt_next

    ; discard if all clipped
    move.b VX_CLIP(a2),d1
    move.b VX_CLIP(a1),d2
    move.b VX_CLIP(a3),d3

    move.b d1,d0
    and.b d2,d0
    and.b d3,d0
    and.b #CLIP_DISCARD,d0
    bne .mt_next

    moveq #0,d7
    move.w MT_FLAGS(a4),d7

    ; frame flag if any vertex touches border
    move.b d1,d0
    or.b d2,d0
    or.b d3,d0
    btst #5,d0
    beq .mt_no_frame
    bset #18,d7

.mt_no_frame:
    ; mark as triangle
    bset #19,d7

    ; depth = (z0+z1+z2*2) >> 6
    move.w VX_Z(a2),d0
    move.w VX_Z(a1),d1
    add.w d1,d0
    move.w VX_Z(a3),d1
    add.w d1,d0
    ext.l d0
    ext.l d1
    add.l d1,d0
    asr.l #6,d0

    ; insert into OT bucket
    move.l (a5,d0.l*4),FC_NEXT(a6)
    move.l a6,(a5,d0.l*4)
    move.l d7,FC_FLAGS(a6)

    ; vertex indices (offset from gVertices)
    move.l a2,d0
    sub.l d5,d0
    asr.l #3,d0

    move.l a1,d1
    sub.l d5,d1
    asr.l #3,d1

    move.l a3,d2
    sub.l d5,d2
    asr.l #3,d2

    movem.w d0-d2,FC_IDX0(a6)

    lea (FC_SIZE,a6),a6

.mt_next:
    addq.l #MT_SIZE,a4
    subq.l #1,d6
    bpl .mt_loop

    move.l a6,_gFacesBase

.mt_ret:
    movem.l (sp)+,d2-d3/d5-d7/a2-a6
    rts
