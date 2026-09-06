;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _transformMesh_asm
    XDEF transformMesh_asm

    XREF _gVerticesBase
    XREF _gMatrixPtr
    XREF _divTable
    XREF _gLightAmbient

; void transformMesh_asm(const MeshVertex* vertices, int32 count, int32 intensity)
; a0=vertices, d0=count, d1=intensity
_transformMesh_asm:
transformMesh_asm:
    movem.l d2-d7/a2-a6,-(sp)
    move.l _gVerticesBase,a1
    move.l _gMatrixPtr,a2
    lea _divTable,a3

    ; per-vertex shade, constant for the whole mesh
    ; clamp((intensity + gLightAmbient) >> 8, 0, 31)
    move.l d1,d3
    add.l _gLightAmbient,d3
    asr.l #8,d3
    tst.l d3
    bge .mesh_clamp_hi
    moveq #0,d3
    bra .mesh_vg_done

.mesh_clamp_hi:
    cmp.l #31,d3
    ble .mesh_vg_done
    moveq #31,d3

.mesh_vg_done:
    subq.l #1,d0
    blt .mesh_ret

.mesh_loop:
    ; load MeshVertex x,y,z, scale by 4
    move.w (a0)+,d1
    ext.l d1
    asl.l #2,d1
    move.w (a0)+,d2
    ext.l d2
    asl.l #2,d2
    move.w (a0)+,d4
    ext.l d4
    asl.l #2,d4

    ; Row 0: x' = e00*x + e01*y + e02*z + (e03 << 14)
    ; muls.l: scaled inputs can exceed 16 bits
    move.w 0(a2),d5
    ext.l d5
    muls.l d1,d5
    move.w 2(a2),d6
    ext.l d6
    muls.l d2,d6
    add.l d6,d5
    move.w 4(a2),d6
    ext.l d6
    muls.l d4,d6
    add.l d6,d5
    move.w 18(a2),d6
    ext.l d6
    asl.l #8,d6
    asl.l #6,d6
    add.l d6,d5
    move.l d5,a5

    ; Row 1: y'
    move.w 6(a2),d5
    ext.l d5
    muls.l d1,d5
    move.w 8(a2),d6
    ext.l d6
    muls.l d2,d6
    add.l d6,d5
    move.w 10(a2),d6
    ext.l d6
    muls.l d4,d6
    add.l d6,d5
    move.w 20(a2),d6
    ext.l d6
    asl.l #8,d6
    asl.l #6,d6
    add.l d6,d5
    move.l d5,a6

    ; Row 2: z'
    move.w 12(a2),d5
    ext.l d5
    muls.l d1,d5
    move.w 14(a2),d6
    ext.l d6
    muls.l d2,d6
    add.l d6,d5
    move.w 16(a2),d6
    ext.l d6
    muls.l d4,d6
    add.l d6,d5
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
    bgt .mesh_zmin_ok
    moveq #$10,d7
    move.l #$100000,d6

.mesh_zmin_ok:
    cmp.l #$A000000,d6
    blt .mesh_zmax_ok
    moveq #$10,d7
    move.l #$A000000,d6

.mesh_zmax_ok:
    ; reduce to 16-bit (>>14)
    asr.l #8,d4
    asr.l #6,d4
    asr.l #8,d5
    asr.l #6,d5
    asr.l #8,d6
    asr.l #6,d6

    ; save z
    move.l d6,a5

    ; perspective divide: dz=z>>4, clamp 1024, d=1/dz
    lsr.l #4,d6
    cmp.l #1025,d6
    blt .mesh_dz_ok
    move.l #1024,d6

.mesh_dz_ok:
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
    ; mesh: no viewport clip, only frame clip
    tst.l d4
    blt .mesh_set_frame
    cmp.l #320,d4
    bgt .mesh_set_frame
    tst.l d5
    blt .mesh_set_frame
    cmp.l #200,d5
    ble .mesh_frame_ok

.mesh_set_frame:
    ori.b #$20,d7

.mesh_frame_ok:
    ; store vertex: x,y,z,g,clip
    move.w d4,(a1)+
    move.w d5,(a1)+
    move.w a5,(a1)+
    move.b d3,(a1)+
    move.b d7,(a1)+

    subq.l #1,d0
    bpl .mesh_loop

.mesh_ret:
    movem.l (sp)+,d2-d7/a2-a6
    rts
