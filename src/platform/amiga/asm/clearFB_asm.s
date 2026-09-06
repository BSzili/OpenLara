;
; OpenLara - Amiga port
;
; 68020+
;

    section .text,code

    XDEF _clearFB_asm
    XDEF clearFB_asm

FB_SIZE = 320*200

_clearFB_asm:
clearFB_asm:
    movem.l d2-d7/a2-a6,-(sp)
    moveq #0,d1
    moveq #0,d2
    moveq #0,d3
    moveq #0,d4
    moveq #0,d5
    moveq #0,d6
    moveq #0,d7
    move.l d1,a2
    move.l d1,a3
    move.l d1,a4
    move.l d1,a5
    move.l d1,a6
    lea FB_SIZE(a0),a0
    move.l #(FB_SIZE/48)-1,d0

.clearFB_loop:
    movem.l d1-d7/a2-a6,-(a0)
    dbra d0,.clearFB_loop
    clr.l -(a0)
    clr.l -(a0)
    clr.l -(a0)
    clr.l -(a0)
    movem.l (sp)+,d2-d7/a2-a6
    rts
