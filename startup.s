; macman by mausimus (c) 2023
; mausimus.github.io
; MIT license
;

;----------------------------------------------------------------------------- vars
; startup code based on https://github.com/Sakura-IT/Amiga-programming-examples
;
            INCLUDE      "defines.s"

            INCDIR       "include"
            INCLUDE      "hardware/cia.i"
            INCLUDE      "hardware/custom.i"
            INCLUDE      "hardware/dmabits.i"
            INCLUDE      "hardware/intbits.i"

;-----------------------------------------------------------------------------

Program:
            bsr.w        OpenGraphicsLibrary
            beq.b        Exit
            bsr.w        DoVariables
            bsr.w        DisableOs
            bsr.w        Main
Quit:       bsr.w        EnableOs
Exit:       bsr.w        CloseGraphicsLibrary
            move.l       vars+oldStack(pc),a7          ;restore old stack
            rts

;-----------------------------------------------------------------------------
;
;out
;a6	vars
;
DoVariables:
            lea          vars(pc),a6

            move.l      4.w,a6 ; execbase

              move.l      #CHIPDATA_MEMSIZE,d0
              move.l      #$10002,d1
              movea.l     $4,a6
              jsr         -198(a6)
              move.l      d0,a0

              lea          vars(pc),a6

  ;set chip pointers
            move.l       a0,screen(a6)
            add.l        #SCREEN_MEMSIZE,a0
            move.l       a0,copperList(a6)

            lea          chipTiles,a0
            move.l       a0,tileData(a6)

            lea          chipSprites,a0
            move.l       a0,spriteData(a6)

            lea          chipHero,a0
            move.l       a0,heroData(a6)

            lea          chipFont,a0
            move.l       a0,fontData(a6)

            lea          chipLogo,a0
            move.l       a0,logoData(a6)

  ;store old stack pointer
            lea          4(a7),a0
            move.l       a0,oldStack(a6)

            rts

;-----------------------------------------------------------------------------
;in
;a6	vars
;
;out
;a5	_custom
;
DisableOs:
  ;save old view
            move.l       gfxBase(a6),a5
            move.l       $22(a5),oldView(a6)
            exg          a5,a6

  ;set no view 
            sub.l        a1,a1
            bsr.b        LoadView

  ;takeover the blitter
            jsr          -456(a6)                    ;gfx OwnBlitter
            jsr          -228(a6)                    ;gfx WaitBlit

            move.l       a5,a6

  ;store hardware registers
            lea          _custom,a5
            move.w       #$c000,d1

            move.w       intenar(a5),d0
            or.w         d1,d0
            move.w       d0,oldIntena(a6)

            add.w        d1,d1
            move.w       dmaconr(a5),d0
            or.w         d1,d0
            move.w       d0,oldDma(a6)

            bra.b        StopDmaAndIntsAtVBlank

;-----------------------------------------------------------------------------
;in
;	a6 - gfx base
;	a1 - view
LoadView:
            jsr          -222(a6)                    ;gfx LoadView(view)
            jsr          -270(a6)                    ;gfx WaitTOF()
            jmp          -270(a6)                    ;gfx WaitTOF()

;-----------------------------------------------------------------------------
;
;in
;	a5 - custom
;
StopDmaAndIntsAtVBlank:
            WAIT_BEAM
            move.w       #$7fff,d0
            move.w       d0,dmacon(a5)               ;dma off
            move.w       d0,intena(a5)               ;disable ints
            move.w       d0,intreq(a5)               ;clear pending ints
            rts

;-----------------------------------------------------------------------------
;in
;a5	custom
;a6	vars
;
EnableOs:
            move.l       a6,a4

            move.l       gfxBase(a4),a6
            jsr          -228(a6)                    ;gfx WaitBlit()

            bsr.b        StopDmaAndIntsAtVBlank

  ;restore hardware regs
            move.w       oldIntena(a4),intena(a5)
            move.w       oldDma(a4),dmacon(a5)

            jsr          -462(a6)                    ;gfx DisownBlitter()

  ;load old view
            move.l       oldView(a4),a1
            bsr.b        LoadView

            move.l       $26(a6),cop1lc(a5)

            move.l       a4,a6
            rts

;-----------------------------------------------------------------------------
;
;in
;a6	vars
;
;out
;d0	zero mean some library do not open 
;	non zero everything were ok
;
OpenGraphicsLibrary:
            move.l       4.w,a6                      ;exec base
            lea          .gfxName(pc),a1             ;library name
            jsr          -408(a6)                    ;exec OldOpenLibrary()
            lea          vars(pc),a6
            move.l       d0,gfxBase(a6)              ;store result of opening
            rts

.gfxName:   dc.b         'graphics.library',0,0

;-----------------------------------------------------------------------------
;
;in
;a6	vars
;
;out
;a6	exec base
;
CloseGraphicsLibrary:
            move.l       gfxBase(a6),a1              ;library base
            move.l       4.w,a6                      ;exec base
            IFND         KICKSTART2
            move.l       a1,d0                       ;trick to check if lib base is zero
            beq.b        .exit
            ENDC
            jsr          -414(a6)                    ;exec CloseLibrary
.exit       rts
