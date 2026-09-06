;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _transformRoom_asm
    XDEF transformRoom_asm
    XDEF _transformRoomUW_asm
    XDEF transformRoomUW_asm

    XREF _gVerticesBase
    XREF _gMatrixPtr
    XREF _divTable
    XREF _viewport
    XREF _gCaustics
    XREF _gRandTable
    XREF _gCausticsFrame

; void transformRoom_asm(const RoomVertex* vertices, int32 count)
; a0=vertices, d0=count
_transformRoom_asm:
transformRoom_asm:
    movem.l d2-d7/a2-a6,-(sp)
    move.l _gVerticesBase,a1
    move.l _gMatrixPtr,a2
    lea _divTable,a3
    lea _viewport,a4

    subq.l #1,d0
    blt .room_done

.room_loop:
    bsr room_dp43
    bsr room_finish
    subq.l #1,d0
    bpl .room_loop

.room_done:
    movem.l (sp)+,d2-d7/a2-a6
    rts

; void transformRoomUW_asm(const RoomVertex* vertices, int32 count)
; a0=vertices, d0=count
; same as transformRoom + caustics shimmer
_transformRoomUW_asm:
transformRoomUW_asm:
    movem.l d2-d7/a2-a6,-(sp)
    sub.l #4,sp
    move.l _gVerticesBase,a1
    move.l _gMatrixPtr,a2
    lea _divTable,a3
    lea _viewport,a4

    subq.l #1,d0
    blt .uw_done

    suba.l a5,a5

.uw_loop:
    ; save vertex index in a5 across dp43 call
    move.l a5,(sp)
    bsr room_dp43
    move.l (sp),a5

    ; Caustics: add gCaustics[(gRandTable[i & 31] + gCausticsFrame) & 31] to vg
    move.l a5,d1
    and.l #31,d1
    lea _gRandTable,a6
    move.l (a6,d1.l*4),d1
    add.l _gCausticsFrame,d1
    and.l #31,d1
    lea _gCaustics,a6
    move.l (a6,d1.l*4),d1
    add.l d1,d3
    tst.l d3
    bge .uw_clamp_hi
    moveq #0,d3
    bra .uw_caustics_done

.uw_clamp_hi:
    cmp.l #8191,d3
    ble .uw_caustics_done
    move.l #8191,d3

.uw_caustics_done:
    bsr room_finish
    addq.l #1,a5
    subq.l #1,d0
    bpl .uw_loop

.uw_done:
    add.l #4,sp
    movem.l (sp)+,d2-d7/a2-a6
    rts

; load RoomVertex bytes, run DP43, clamp z
; in: a0=vertices, a2=matrix
; out: d3=vg, d4=x, d5=y, d6=z, d7=clip
; clobbers d1, d2, a0+4, a5, a6
room_dp43:
    ; load RoomVertex bytes zero-extended (uint8 x,y,z,g)
    moveq #0,d1
    move.b (a0)+,d1
    moveq #0,d2
    move.b (a0)+,d2
    moveq #0,d4
    move.b (a0)+,d4
    moveq #0,d3
    move.b (a0)+,d3
    lsl.l #5,d3

    ; Row 0: x' = (e00*x + e01*y + e02*z) << 8 + (e03 << 14)
    move.w 0(a2),d5
    muls.w d1,d5
    move.w 2(a2),d6
    muls.w d2,d6
    add.l d6,d5
    move.w 4(a2),d6
    muls.w d4,d6
    add.l d6,d5
    lsl.l #8,d5
    move.w 18(a2),d6
    ext.l d6
    asl.l #8,d6
    asl.l #6,d6
    add.l d6,d5
    move.l d5,a5

    ; Row 1: y'
    move.w 6(a2),d5
    muls.w d1,d5
    move.w 8(a2),d6
    muls.w d2,d6
    add.l d6,d5
    move.w 10(a2),d6
    muls.w d4,d6
    add.l d6,d5
    lsl.l #8,d5
    move.w 20(a2),d6
    ext.l d6
    asl.l #8,d6
    asl.l #6,d6
    add.l d6,d5
    move.l d5,a6

    ; Row 2: z'
    move.w 12(a2),d5
    muls.w d1,d5
    move.w 14(a2),d6
    muls.w d2,d6
    add.l d6,d5
    move.w 16(a2),d6
    muls.w d4,d6
    add.l d6,d5
    lsl.l #8,d5
    move.w 22(a2),d6
    ext.l d6
    asl.l #8,d6
    asl.l #6,d6
    add.l d6,d5

    ; shuffle: d4=x d5=y d6=z
    move.l d5,d6
    move.l a6,d5
    move.l a5,d4

    ; z clamp: near=$100000 far=$A000000, clip=$10
    moveq #0,d7
    cmp.l #$100000,d6
    bgt .dp43_zmin_ok
    moveq #$10,d7
    move.l #$100000,d6

.dp43_zmin_ok:
    cmp.l #$A000000,d6
    blt .dp43_zmax_ok
    moveq #$10,d7
    move.l #$A000000,d6

.dp43_zmax_ok:
    rts

; Shifts, fog, perspective, frame clip, viewport clip, store
; in: d3=vg, d4=x, d5=y, d6=z, d7=clip
; a1=output, a3=divTable, a4=viewport
; clobbers d1, d2, d6
room_finish:
    ; reduce to 16-bit (>>14)
    asr.l #8,d4
    asr.l #6,d4
    asr.l #8,d5
    asr.l #6,d5
    asr.l #8,d6
    asr.l #6,d6

    ; fog: beyond z=8192, darken vg by (z-8192)*2, clamp 8191
    cmp.l #8192,d6
    ble .finish_fog_ok
    move.l d6,d1
    sub.l #8192,d1
    asl.l #1,d1
    add.l d1,d3
    cmp.l #8191,d3
    ble .finish_fog_ok
    move.l #8191,d3

.finish_fog_ok:
    ; save z
    move.l d6,d2

    ; perspective divide: dz=z>>4, clamp 1024, d=1/dz
    lsr.l #4,d6
    cmp.l #1025,d6
    blt .finish_dz_ok
    move.l #1024,d6

.finish_dz_ok:
    moveq #0,d1
    move.w (a3,d6.l*2),d1

    ; x = (x * d) >> 12, y = (y * d) >> 12
    muls.l d1,d4
    asr.l #8,d4
    asr.l #4,d4
    muls.l d1,d5
    asr.l #8,d5
    asr.l #4,d5

    ; center on screen
    add.l #160,d4
    add.l #100,d5

    ; frame clip: $20 if outside 0..320 x 0..200
    tst.l d4
    blt .finish_set_frame
    cmp.l #320,d4
    bgt .finish_set_frame
    tst.l d5
    blt .finish_set_frame
    cmp.l #200,d5
    ble .finish_frame_ok

.finish_set_frame:
    ori.b #$20,d7

.finish_frame_ok:
    ; viewport clip: bits 0-3 for L/R/T/B
    cmp.l 0(a4),d4
    bge .finish_no_left
    ori.b #1,d7

.finish_no_left:
    cmp.l 8(a4),d4
    ble .finish_no_right
    ori.b #2,d7

.finish_no_right:
    cmp.l 4(a4),d5
    bge .finish_no_top
    ori.b #4,d7

.finish_no_top:
    cmp.l 12(a4),d5
    ble .finish_no_bottom
    ori.b #8,d7

.finish_no_bottom:
    ; store vertex: x,y,z,g>>8,clip
    move.w d4,(a1)+
    move.w d5,(a1)+
    move.w d2,(a1)+
    lsr.l #8,d3
    move.b d3,(a1)+
    move.b d7,(a1)+
    rts
