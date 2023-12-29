; macman by mausimus (c) 2023
; mausimus.github.io
; MIT license
;
			INCLUDE			"defines.s"

			INCDIR			"include"
			INCLUDE			"hardware/cia.i"
			INCLUDE			"hardware/custom.i"
			INCLUDE			"hardware/dmabits.i"
			INCLUDE			"hardware/intbits.i"

;-----------------------------------------------------------------------------
Main:
			bsr.w			Init
			bsr				ColorsSet
			bsr				BlitLogoToScreen
			bsr				DrawText
			move.w			#0,highScore(a6)
NewGame:			
			bsr				Restart

Loop:		WAIT_BEAM
			bsr				CheckPellet
			bsr				UpdateHero

			; check for death and break loop
			bsr				CheckDeath
			cmp.w			#1,dead(a6)
			beq				GameOver

			bsr				UpdateSprites

			; check for death and break loop
			bsr				CheckDeath
			cmp.w			#1,dead(a6)
			beq				GameOver

			bsr				DrawHero
			bsr				DrawSprites
			add				#1,frameNo(a6)			

			; game over?
			cmp.w			#244,dotsEaten(a6)
			beq				GameOver

.checkLmb
			btst			#6,_ciaa
			bne.b			Loop
			rts

GameOver:
			move.l			#DEATH_TIME,d1 ; wait 50 frames
.loop1:			
			WAIT_BEAM
			dbra			d1,.loop1

			; update high score
			move.w          score(a6),d0
			cmp.w           highScore(a6),d0
			blt				.no_hs
			move.w          d0,highScore(a6)
			bsr				DrawHighScore

			; wait extra to showcase HS
			move.l			#DEATH_TIME,d1 ; wait 50 frames
.loop2:			
			WAIT_BEAM
			dbra			d1,.loop2
.no_hs:			

			cmp.w			#244,dotsEaten(a6)
			bne				.new_game
			bsr				DrawGG
			; wait extra to showcase GG
			move.l			#DEATH_TIME,d1 ; wait 50 frames
.loop3:			
			WAIT_BEAM
			dbra			d1,.loop3

.new_game
			bra				NewGame

Restart:
			bsr				DrawMap
			bsr				Reset
			bsr				ClearGG
			bsr				DrawPlayerScore
			bsr				DrawHighScore
			rts

Reset:
			move.w			#0,frameNo(a6)
			move.w			#0,score(a6)
			move.w			#0,pellet(a6)
			move.w			#0,dead(a6)
			move.w			#0,dotsEaten(a6)

			; hero start
			GET_HERO
			move.w			#104,OBJ_X(a0)
			move.w			#180,OBJ_Y(a0)
			move.w			#0,OBJ_F(a0)
			move.w			#0,OBJ_D(a0)
			move.w			#0,OBJ_S(a0)

			; ghosts start
			GET_GHOSTS
			move.w			#$64,OBJ_X(a0)
			move.w			#$60,OBJ_Y(a0)
			move.w			#0,OBJ_D(a0)
			move.w			#0,OBJ_F(a0)
			move.w			#0,OBJ_S(a0)
			
			add.l			#OBJ_SIZE,a0
			move.w			#$64,OBJ_X(a0)
			move.w			#$64,OBJ_Y(a0)
			move.w			#0,OBJ_D(a0)
			move.w			#0,OBJ_F(a0)
			move.w			#0,OBJ_S(a0)

			add.l			#OBJ_SIZE,a0
			move.w			#$6c,OBJ_X(a0)
			move.w			#$60,OBJ_Y(a0)
			move.w			#0,OBJ_D(a0)
			move.w			#0,OBJ_F(a0)
			move.w			#0,OBJ_S(a0)

			add.l			#OBJ_SIZE,a0
			move.w			#$6c,OBJ_X(a0)
			move.w			#$64,OBJ_Y(a0)
			move.w			#0,OBJ_D(a0)
			move.w			#0,OBJ_F(a0)
			move.w			#0,OBJ_S(a0)
			rts

IsCrossRoads:
; d0 - x
; d1 - y
; ret: d6
			; get grid coords
			move.w			d0,d3
			sub.w			#4,d3
			and.w			#7,d3
			move.w			d1,d4
			sub.w			#4,d4
			and.w			#7,d4

			; are we on crossroads? d3 and d4 zero
			cmp.w			#0,d3
			bne				.notcross
			cmp.w			#0,d4
			bne				.notcross

			; crossroads
			move.l			#1,d6
			bra				.done
.notcross:
			move.l			#0,d6
.done						
			rts

; is it possible to move in direction d
; d0 - x
; d1 - y
; d2 - direction (0,1,2,3)
CanMove:
			; starting position is 4x4 and steps are 8x8
			; we can move horizontally if y-4 is divisible by 8

			; get grid coords
			move.w			d0,d3
			sub.w			#4,d3
			and.w			#7,d3
			move.w			d1,d4
			sub.w			#4,d4
			and.w			#7,d4

			; are we on crossroads? d3 and d4 zero
			cmp.w			#0,d3
			bne				.notcross
			cmp.w			#0,d4
			bne				.notcross

			; crossroads - check tile to move into
			bsr				CanEnterTile
			bra				.done

.notcross:
			cmp.w			#0,d2
			beq				.up
			cmp.w			#1,d2
			beq				.right
			cmp.w			#2,d2
			beq				.down
			cmp.w			#3,d2
			beq				.left
			bra				.done
.up:
			sub.w			#4,d0
			and.w			#7,d0
			cmp.w			#0,d0
			bne				.cant
			bra				.can
.down:
			sub.w			#4,d0
			and.w			#7,d0
			cmp.w			#0,d0
			bne				.cant
			bra				.can
.left:
			sub.w			#4,d1
			and.w			#7,d1
			cmp.w			#0,d1
			bne				.cant
			bra				.can
.right:
			sub.w			#4,d1
			and.w			#7,d1
			cmp.w			#0,d1
			bne				.cant
			bra				.can
.can:
			move.l			#1,d0
			bra				.done
.cant:
			move.l			#0,d0
			bra				.done
.done:			
			rts

CanEnterTile:
; d0 - x
; d1 - y
; d2 - direction (0,1,2,3)
			; calculate tile coords
			move.w			d0,d3
			move.w			d1,d4
			; remove 4x4 margin
			sub.w			#4,d3
			sub.w			#4,d4
			; divide by 8 and add 1
			asr.w			#3,d3
			asr.w			#3,d4
			add.w			#1,d3
			add.w			#1,d4

			; adjust by desired direction
			cmp.w			#0,d2
			beq				.up
			cmp.w			#1,d2
			beq				.right
			cmp.w			#2,d2
			beq				.down
			cmp.w			#3,d2
			beq				.left
			bra				.check
.up:
			sub.w			#1,d4
			bra				.check
.down:
			add.w			#1,d4
			bra				.check
.left:
			sub.w			#1,d3
			bra				.check
.right:
			add.w			#1,d3
			bra				.check

.check:
			; get tile coords
			mulu			#MAP_W,d4
			add.w			d4,d3 ; d3 is tile no
			;movem.l			a0,-(sp)
			lea				map,a1
			move.b			(a1,d3),d4 ; d4 is tile type
			;movem.l			(sp)+,a0
			cmp.b			#2,d4 ; only 0/1/2 are open tiles
			bgt				.cant
			move.l          #1,d0
			bra				.done
.cant:
			move.l			#0,d0
.done:			
			rts

ClearTile:
; d0 - obj x
; d1 - obj y
			; calculate tile coords
			move.w			d0,d3
			move.w			d1,d4
			; move to center
			add.w			#8,d3
			add.w			#8,d4
			; divide by 8
			asr.w			#3,d3
			asr.w			#3,d4

			; check tile type
			lea				map,a1
			move.l			d4,d1
			mulu			#MAP_W,d1
			add.l			d3,d1
			move.b			(a1,d1),d0 ; tile type
			cmp.b			#0,d0
			beq				.skip ; empty
			btst			#7,d0
			bne				.skip ; already cleared

			; record dot being eaten
			add.w			#1,dotsEaten(a6)

			; add points
			add.w			#BASE_POINTS,score(a6) ; base points
			cmp.b			#2,d0 ; pellet?
			bne				.clear
			add.w			#PELLET_POINTS,score(a6) ; extra points
			add.w			#PELLET_TIME,pellet(a6) ; add pellet time

			; make all ghosts vuln
			bsr				MakeGhostsVulnerable

.clear:			
			add.b			#128,d0 ; set cleared bit
			move.b			d0,(a1,d1) ; clear in map			
			
			; d3,d4 are tile coords
			clr.l			d0
			add.l			d3,d0
			mulu			#(MAP_ROW_SIZE),d4
			add.l			d4,d0
			move.l			#0,d1 ; clear tile
			bsr				BlitTileToScreen
			bsr				DrawPlayerScore
.skip
			rts

MakeGhostsVulnerable:
			movem			d0/a0,-(sp)
			GET_GHOSTS
			move.l			#(NUM_SPRITES-1),d0
.loop:
			cmp.w			#2,OBJ_S(a0)
			beq				.skip ; ignore returning ghost
			move.w			#1,OBJ_S(a0)
.skip:			
			add.l			#OBJ_SIZE,a0			
			dbra			d0,.loop
			movem			(sp)+,d0/a0
			rts

DrawPlayerScore:
			clr.l			d4
			move.w			score(a6),d4
			move.l			#(32+160*9),d0 ; X position
			bsr				DrawScore
			rts

DrawHighScore:
			clr.l			d4
			move.w			highScore(a6),d4
			move.l			#(32+160*9*4),d0 ; X position
			bsr				DrawScore
			rts

; d0 - screen position
; d4 - score
DrawScore:			
; 10000s
			clr.l			d1
.10000:		
			cmp.w			#10000,d4
			blt				.10000done
			add.b			#16,d1 ; incr digit
			sub.w			#10000,d4 ; remove from score
			bra				.10000
.10000done:
			bsr				BlitCharToScreen ; d0-position,d1-digit
			add.l			#1,d0 ; next position

; 1000s
			clr.l			d1
.1000:		
			cmp.w			#1000,d4
			blt				.1000done
			add.b			#16,d1 ; incr digit
			sub.w			#1000,d4 ; remove from score
			bra				.1000
.1000done:
			bsr				BlitCharToScreen ; d0-position,d1-digit
			add.l			#1,d0 ; next position

; 100s
			clr.l			d1
.100:		
			cmp.w			#100,d4
			blt				.100done
			add.b			#16,d1 ; incr digit
			sub.w			#100,d4 ; remove from score
			bra				.100
.100done:
			bsr				BlitCharToScreen ; d0-position,d1-digit
			add.l			#1,d0 ; next position

; 10s
			clr.l			d1
.10:		
			cmp.w			#10,d4
			blt				.10done
			add.b			#16,d1 ; incr digit
			sub.w			#10,d4 ; remove from score
			bra				.10
.10done:
			bsr				BlitCharToScreen ; d0-position,d1-digit
			add.l			#1,d0 ; next position

; always 0 last
			clr.l			d1
			bsr				BlitCharToScreen ; d0-position,d1-digit
			rts

CheckPellet:
			cmp.w			#0,pellet(a6)
			beq				.done
			sub.w			#1,pellet(a6)
			cmp.w			#0,pellet(a6)
			bne				.done
			; clear state flag off ghosts
			GET_GHOSTS
			move.l			#(NUM_SPRITES-1),d2
.loop:
			cmp.w			#2,OBJ_S(a0)
			beq				.skip ; skip returning ghost
			move.w			#0,OBJ_S(a0)
.skip:			
			add.l			#OBJ_SIZE,a0 ; next ghost
			dbra			d2,.loop

.done:
			rts			

CheckDeath:
			; for each ghost check if same tile
			GET_HERO
			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			; move to center
			add.w			#8,d0
			add.w			#8,d1
			; divide by 8
			asr.w			#3,d0
			asr.w			#3,d1

			GET_GHOSTS
			move.l			#(NUM_SPRITES-1),d2
.loop:
			clr.l			d3
			clr.l			d4
			move.w			OBJ_X(a0),d3
			move.w			OBJ_Y(a0),d4
			; move to center
			add.w			#8,d3
			add.w			#8,d4
			; divide by 8
			asr.w			#3,d3
			asr.w			#3,d4
			cmp.w			d0,d3
			bne				.not_dead
			cmp.w			d1,d4
			bne				.not_dead

			; someone's dead
			move.w			OBJ_S(a0),d3
			cmp.w			#2,d3
			beq				.not_dead ; ghost is returning, ignore
			cmp.w			#1,d3
			bne				.hero_dead
			; ghost is dead, tell it to return
			move.w			#2,OBJ_S(a0)
			
			; add points
			add.w			#GHOST_POINTS,score(a6)
			bra				.not_dead

.hero_dead
			move.w			#1,dead(a6)
			bra				.done

.not_dead:		
			add.l			#OBJ_SIZE,a0 ; next ghost
			dbra			d2,.loop
.done			
			rts

UpdateHero:
			GET_HERO

			bsr				GetJoystick
			cmp.w			#4,d0
			beq				.noinput

			move.l			d0,d2 ; desired direction
			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			bsr				CanMove
			cmp.w			#1,d0
			bne				.noinput
			move.w			d2,OBJ_D(a0) ; update direction to desired
.noinput:
			; can we move in current direction
			clr.l			d2
			move.w			OBJ_D(a0),d2 ; current direction
			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			bsr				CanMove
			cmp.w			#1,d0
			bne				.stop

			bsr				MoveObject

			clr.l d0
			clr.l d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			bsr				ClearTile
.stop:	
			rts

ReturnDir:
; d0,d1 = x,y
; get return direction in d2
			movem.l			d3/d4/a1,-(sp)

			; calculate tile coords
			clr.l			d3
			clr.l			d4
			move.w			d0,d3
			move.w			d1,d4
			; remove 4x4 margin
			sub.w			#4,d3
			sub.w			#4,d4
			; divide by 8 and add 1
			asr.w			#3,d3
			asr.w			#3,d4
			add.w			#1,d3
			add.w			#1,d4

			mulu			#MAP_W,d4
			add.w			d4,d3
			lea				return,a1
			clr.l			d2
			move.b			(a1,d3),d2 ; d2 is return dir
			and.l			#3,d2
			movem.l			(sp)+,d3/d4/a1
			rts

; get random direction in d2
RandomDir:
			; get frame no
			movem.l			d0,-(sp)
			clr.l			d0
			move.w			frameNo(a6),d0
			
			; add player direction
            move.l			a6,a1
            add.l			#hero,a1
			move.w			OBJ_D(a1),d2
			add.w			d2,d0

			lea				rng,a1
			and.l			#63,d0
			clr.l 			d2
			move.b			(a1,d0),d2
			movem.l			(sp)+,d0
			rts

; a0 - sprite base address (xydf)
UpdateSprite:
			; should we change direction? if on crossroads
			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			bsr				IsCrossRoads
			cmp				#1,d6
			bne				.move

			; are we returning?
			move.w			OBJ_S(a0),d3
			cmp.w			#2,d3
			bne				.try_random

			; are we home?
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			cmp.w			#$64,d1 ; y=$64
			bne				.try_return
			cmp.w			#$6c,d0 ;x=$6c or $64
			beq				.home
			cmp.w			#$64,d0
			beq				.home
			bra				.try_return
.home:
			; we are home, reset and skip
			move.w			#0,OBJ_S(a0)
			bra				.done

			; try switch to return direction
.try_return:
			bsr				ReturnDir
			bsr				CanMove
			cmp.w			#1,d0
			bne				.move
			move.w			d2,OBJ_D(a0)
			bra				.move

			; try random direction but not reverse
.try_random:
			bsr				RandomDir
			move.w			OBJ_D(a0),d3
			sub.w			d2,d3
			cmp.w			#2,d3
			beq				.move
			cmp.w			#-2,d3
			beq				.move
			cmp.w			#0,d3
			beq				.move
			
			bsr				CanMove
			cmp.w			#1,d0
			bne				.move
			move.w			d2,OBJ_D(a0)

.move:
			; can we move in current direction
			clr.l			d2
			move.w			OBJ_D(a0),d2 ; current direction
			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0
			move.w			OBJ_Y(a0),d1
			bsr				CanMove
			cmp.w			#1,d0
			beq				.domove

			; random direction if we're stuck
			bsr				RandomDir
			move.w			d2,OBJ_D(a0)

			bra				.done
.domove:
			; half speed if we are poisoned
			move.w			OBJ_S(a0),d2
			cmp.w			#1,d2
			bne				.actuallymove
			; check if frame is even
			move.w			frameNo(a6),d2
			btst			#0,d2
			bne				.done
.actuallymove:
			bsr				MoveObject
.done:	
			rts

;---------------------------------------------
;move object in desired direction
;a0 - object ptr
MoveObject:
			move.w			OBJ_D(a0),d0
			cmp.w			#0,d0
			beq				.up
			cmp.w			#1,d0
			beq				.right
			cmp.w			#2,d0
			beq				.down
			cmp.w			#3,d0
			beq				.left
.down:
			add.w			#1,OBJ_Y(a0)
			bra				.done
.up:
			sub.w			#1,OBJ_Y(a0)
			bra				.done
.right:			
			add.w			#1,OBJ_X(a0)
			bra				.done
.left:
			sub.w			#1,OBJ_X(a0)
			bra				.done
.done
			add.w			#1,OBJ_F(a0)

			; check for warp
			cmp.w			#$6c,OBJ_Y(a0)
			bne				.return
			cmp.w			#$3,OBJ_X(a0)
			ble				.warp_l
			cmp.w			#$cd,OBJ_X(a0)
			bge				.warp_r
			bra				.return
.warp_l:
			; clear on screen
			bsr				ClearWarp
			move.w			#$cc,OBJ_X(a0)
			bra				.return
.warp_r:
			; clear on screen
			bsr				ClearWarp
			move.w			#$4,OBJ_X(a0)
			bra				.return
.return
			rts

; clear screen around warping areas to remove ghosting
ClearWarp:
			WAIT_BLITTER
			move.l			#(0+160*108),d0
			move.w			#(SCREEN_BROW*4-4),bltdmod(a5)
			move.l			#$01f00000,bltcon0(a5)                                                      
			move.w			#$0000,bltadat(a5)
			move.l			screen(a6),d2
			add.l			d0,d2
			add.l			#(SCREEN_BROW*3),d2
			move.l			d2,bltdpt(a5)
			move.w			#16*64+2,bltsize(a5)
			WAIT_BLITTER
			move.l			#(24+160*108),d0
			move.l			screen(a6),d2
			add.l			d0,d2
			add.l			#(SCREEN_BROW*3),d2
			move.l			d2,bltdpt(a5)			
			move.w			#16*64+2,bltsize(a5)
			rts

; return direction the joystick is pointing
GetJoystick:
			move.l			joy0dat(a5),d0
			and.w			#%1,d0 ; bit 0
			move.l			joy0dat(a5),d1
			and.w			#%10,d1 ; bit 1
			asr.w			#1,d1
			eor				d0,d1
			bne				.back

			move.l			joy0dat(a5),d0
			and.w			#%1000000000,d0 ; bit 9
			asr.w			#8,d0
			asr.w			#1,d0
			move.l			joy0dat(a5),d1
			and.w			#%100000000,d1 ; bit 8
			asr.w			#8,d1
			eor				d0,d1
			bne				.front

			move.l			joy0dat(a5),d0
			btst			#1,d0
			bne				.right
			btst			#9,d0
			bne				.left
			move.l			#4,d0 ; no direction
			bra				.done

.back:
			move.l			#2,d0
			bra				.done
.front:
			move.l			#0,d0
			bra				.done
.right:			
			move.l			#1,d0
			bra				.done
.left:
			move.l			#3,d0
			bra				.done
.done
			rts

UpdateSprites:
			GET_GHOSTS
			move.l			#(NUM_SPRITES-1),d5 ; num sprites
.sprite_loop:
			bsr				UpdateSprite

			; next sprite
			add.l			#OBJ_SIZE,a0

			dbra			d5,.sprite_loop
			rts

;-----------------------------------------------------------------------------
;	WRITE SPRITE POSITIONS TO SPRITE DATA
;	a5 - _custom
DrawSprites:
			GET_GHOSTS
			move.l			spriteData(a6),a2
			add.l			#(SPRITE_SIZE),a2 ; skip dummy sprite
			move.l			copperSprites(a6),a3 ; address of sprite entries in copper list
			move.l			#(NUM_SPRITES-1),d2 ; num sprites

			; need to calculate which sprite to use by frame and sprite no
			; update coords on that sprite
			; then put its address in copperlist

.sprite_loop:
			; add frame offset to a2
			clr.l			d3
			move.w			OBJ_S(a0),d3
			cmp.w			#2,d3 ; are we returning?
			beq				.returning
			cmp.w			#1,d3 ; are we poisoned?
			bne				.alive
			; is pellet ending?
			move.w			pellet(a6),d3
			cmp.w			#PELLET_ALERT,d3
			bge				.not_ending
			move.w			frameNo(a6),d3
			btst			#4,d3 ; flash 16 frames
			beq				.not_ending
			move.w			#5,d3 ; show 5th frame
			bra				.frame
.not_ending:
			move.w			#4,d3 ; show 4th frame
			bra				.frame
.returning:
			move.w			OBJ_D(a0),d3
			add.w			#12,d3
			mulu			#(SPRITE_SIZE),d3
			bra				.continue
.alive:
			move.w			OBJ_D(a0),d3
.frame:
			mulu			#(SPRITE_SIZE*2),d3

			; frame no
			move.w			OBJ_F(a0),d0
			asr.l			#2,d0 ; every 4 screen frames
			btst			#0,d0
			beq.s			.continue
			add.l			#SPRITE_SIZE,d3 ; next frame
.continue:
			add.l			d3,a2

			clr.l			d0
			clr.l			d1
			move.w			OBJ_X(a0),d0 ; x pos of first sprite
			add.w			#$81,d0 ; screen start offset
			asr.w			#1,d0 ; div 2
			move.w			OBJ_Y(a0),d1 ; y pos of first sprite
			add.w           #$2c,d1 ; screen start offset
			asl.w			#8,d1 ; V START
			add.w			d0,d1 ; H START/2
			; d1 = write SPRxPOS
			move.w			d1,(a2)

			move.w			OBJ_Y(a0),d1 ; y pos of first sprite
			add.w           #$2c,d1 ; screen start offset
			add.w			#16,d1
			asl.w			#8,d1 ; V STOP
			; V START HIGH?
			move.w			OBJ_Y(a0),d0 ; y pos of first sprite
			add.w           #$2c,d0 ; screen start offset
			cmp.w			#256,d0
			blt				.vstartlow
			add.w			#4,d1 ; V START HIGH
.vstartlow:
			; V STOP HIGH?
			add.w			#16,d0
			cmp.w			#256,d0
			blt				.vstoplow
			add.w			#2,d1; V STOP HIGH
.vstoplow:
			move.w			OBJ_X(a0),d0 ; x pos of first sprite
			add.w			#$81,d0 ; screen start offset
			and.l			#1,d0
			add.w			d0,d1 ; HSTART LOW

			; d1 = write SPRxCTL
			move.w			d1,2(a2)

			; next sprite
			add.l			#OBJ_SIZE,a0

			; write a2 to copperlist
			move.l			a2,d4
			move.w			d4,6(a3) ; low word
			swap			d4
			move.w			d4,2(a3) ; hi word

			sub.l			d3,a2
			add.l			#(SPRITE_SIZE*SPRITE_FRAMES),a2 ; 10 frames
			add.l			#16,a3 ; next sprite on copper list, but skip one for palettes

			dbra			d2,.sprite_loop
			rts

; restore map by clearing visited bits
ClearMap:
			lea				map,a0 ; map pointer
			move.l			#(MAP_W*MAP_H-1),d0
.loop:
			move.b			(a0),d1
			btst			#7,d1
			beq				.next
			sub.b			#128,d1 ; clear visited bit
			move.b			d1,(a0)
.next:
			add.l			#1,a0
			dbra			d0,.loop
			rts

;-----------------------------------------------------------------------------
;	DRAW MAP BY BLITTING TILES TO SCREEN
;	a5 - _custom
DrawMap:
			bsr				ClearMap

			move.l			#0,d0 ; screen offset in bitplane bytes
			move.l			#0,d1 ; tile offset in bytes
			lea				map,a0 ; map pointer

			move.l			#(MAP_H-1),d4 ; V loop
.line_loop:
			move.l			#(MAP_W-1),d3 ; H loop
.col_loop:
           	; lookup map tile at current offset
			clr.l			d1  
			move.b			(a0),d1 	; load tile number from map
			asl.l			#6,d1 		; shift offset by tile size (64)
			add.l			#1,a0		; increment map pointer

			bsr				BlitTileToScreen
			add.l			#MAP_COL_STEP,d0 ; move to next position on screen
			dbra			d3,.col_loop

			add.l			#(MAP_ROW_STEP),d0 ; jump to next line position
			dbra			d4,.line_loop
			rts

;-----------------------------------------------------------------------------
;	BLIT TILE TO SCREEN
;	a5 - _custom
;	d0 - screen offset (bytes)
;	d1 - data offset (bytes)
BlitTileToScreen:
			WAIT_BLITTER
			moveq			#0,d2

			move.w			d2,bltamod(a5)				; modulo A (src)
			move.w			#SCREEN_BROW-2,bltdmod(a5)	; modulo D (dst)

			btst			#0,d0
			beq.s			.even
.odd:
			; Blitter only works on words so if byte offset is odd, we need to offset and mask left side by a byte
			move.w			#SCREEN_BROW-2,bltcmod(a5)
			move.l			#$8be20000,bltcon0(a5)                                                      
			move.w			#$ff,bltbdat(a5)
			move.l			#%11111111111111111111111100000000,d2
			move.l			d2,bltafwm(a5)
			bra				.done
.even:
			move.w			#SCREEN_BROW-2,bltcmod(a5)
			move.l			#$0be20000,bltcon0(a5)                                                      
			move.w			#$ff00,bltbdat(a5)
			move.l			#$ffffffff,d2
			move.l			d2,bltafwm(a5)
.done:
			move.l			screen(a6),d2
			add.l			d0,d2
			move.l			d2,bltdpt(a5)			
			move.l			d2,bltcpt(a5) ; C (screen) only used when masking

			move.l			tileData(a6),d2
			add.l			d1,d2
			move.l			d2,bltapt(a5)

			move.w			#MAP_TILE_SIZE*SCREEN_BPL*64+1,bltsize(a5)	; do the BLIT (H << 6 + W)
			rts

DrawText:
			move.l			#2,d3
			move.l			#(34+160*9*0),d0
			move.l			#(11*16),d1
.loop1:
			bsr				BlitCharToScreen
			add.l			#1,d0
			add.l			#16,d1
			dbra			d3,.loop1

			move.l			#3,d3
			move.l			#(33+160*9*3),d0
			move.l			#(14*16),d1
.loop2:
			bsr				BlitCharToScreen
			add.l			#1,d0
			add.l			#16,d1
			dbra			d3,.loop2
			rts

DrawGG:
			move.l			#1,d3
			move.l			#(35+160*9*6),d0
			move.l			#(16*16),d1
.loop:
			bsr				BlitCharToScreen
			add.l			#1,d0
			dbra			d3,.loop
			rts

ClearGG:
			move.l			#1,d3
			move.l			#(35+160*9*6),d0
			move.l			#(10*16),d1
.loop:
			bsr				BlitCharToScreen
			add.l			#1,d0
			dbra			d3,.loop
			rts

;-----------------------------------------------------------------------------
;	BLIT CHAR TO SCREEN
;	a5 - _custom
;	d0 - screen offset (bytes)
;	d1 - data offset (bytes)
BlitCharToScreen:
			WAIT_BLITTER
			moveq			#0,d2

			move.w			d2,bltamod(a5)				; modulo A (src)
			move.w			#(SCREEN_BROW*4-2),bltdmod(a5)	; modulo D (dst)

			btst			#0,d0
			beq.s			.even
.odd:
			; Blitter only works on words so if byte offset is odd, we need to offset and mask left side by a byte
			move.w			#(SCREEN_BROW*4-2),bltcmod(a5)
			move.l			#$8be20000,bltcon0(a5)                                                      
			move.w			#$ff,bltbdat(a5)
			move.l			#%11111111111111111111111100000000,d2
			move.l			d2,bltafwm(a5)
			bra				.done
.even:
			move.w			#(SCREEN_BROW*4-2),bltcmod(a5)
			move.l			#$0be20000,bltcon0(a5)                                                      
			move.w			#$ff00,bltbdat(a5)
			move.l			#$ffffffff,d2
			move.l			d2,bltafwm(a5)
.done:
			move.l			screen(a6),d2
			add.l			d0,d2

			add.l			#(SCREEN_BROW*2),d2 ; move to 3rd bitplane

			move.l			d2,bltdpt(a5)			
			move.l			d2,bltcpt(a5) ; C (screen) only used when masking

			move.l			fontData(a6),d2
			add.l			d1,d2
			move.l			d2,bltapt(a5)

			move.w			#FONT_SIZE*64+1,bltsize(a5)	; do the BLIT (H << 6 + W)
			rts

; blit to two bit-planes
BlitLogoToScreen:
			WAIT_BLITTER
			move.l			#(38+160*250),d0
			move.w			#0,bltamod(a5)				; modulo A (src)
			move.w			#(SCREEN_BROW*4-1),bltdmod(a5)	; modulo D (dst)
			move.l			#$09f00000,bltcon0(a5)                                                      
			move.l			#$ffffffff,bltafwm(a5)
			move.l			screen(a6),d2
			add.l			d0,d2
			move.l			d2,bltdpt(a5)			
			move.l			logoData(a6),d2
			move.l			d2,bltapt(a5)
			move.w			#4*64+1,bltsize(a5)	; do the BLIT (H << 6 + W)
			WAIT_BLITTER
			move.l			screen(a6),d2
			add.l			d0,d2
			add.l			#(SCREEN_BROW*2),d2 ; move to 3rd bitplane
			move.l			d2,bltdpt(a5)			
			move.l			logoData(a6),d2
			move.l			d2,bltapt(a5)
			move.w			#4*64+1,bltsize(a5)	; do the BLIT (H << 6 + W)

			rts

;-----------------------------------------------------------------------------
;	BLIT HERO TO SCREEN - we only blit 4th bitplane
;	a5 - _custom
DrawHero:
			WAIT_BLITTER
			move.w			#0,bltamod(a5)				; modulo A (src)
			move.w			#(SCREEN_BROW*4-4),bltdmod(a5)	; modulo D (dst)

			; calculate frame (data offset)
			clr.l			d1

			GET_HERO

			; direction
			move.w			OBJ_D(a0),d0
			mulu			#128,d0
			add.w			d0,d1

			move.w			OBJ_F(a0),d0
			asr.l			#2,d0 ; every 4 screen frames
			btst			#0,d0
			beq.s			.continue
			add.w			#64,d1 ; next frame
.continue:
			; calculate screen offset	
			; 1 bit plane row is 40 bytes
			; 4 bit plane rows is 160 bytes
			; ofs = y*160+x
			clr.l			d3
			clr.l			d0
			move.w			OBJ_X(a0),d3 ; X offset in pixels
			asr.l			#3,d3 ; X offset in bytes
			move.w			OBJ_Y(a0),d0
			muls.w			#160,d0
			add.l			d3,d0

			; if we're not on 16 pixel boundary, we'll need to shift
			clr.l 			d4
			move.w			OBJ_X(a0),d4
			and.l			#15,d4 ; X offset in pixels % 16
			cmp.l			#0,d4
			beq.s			.even ; 16 pix boundary
			move.l			#28,d3
			asl.l			d3,d4
			add.l			#$09f00000,d4
			move.l			d4,bltcon0(a5)
			bra				.done
.even:
			move.l			#$09f00000,bltcon0(a5)
.done:
			move.l			#$ffffffff,d2
			move.l			d2,bltafwm(a5)
			move.l			screen(a6),d2
			add.l			d0,d2
			add.l			#(SCREEN_BROW*3),d2 ; move to 4th bitplane
			move.l			d2,bltdpt(a5)

			move.l			heroData(a6),d2
			add.l			d1,d2
			move.l			d2,bltapt(a5)

			move.w			#HERO_SIZE*64+2,bltsize(a5)	; do the BLIT (H << 6 + W)
			rts

;-----------------------------------------------------------------------------
;
;in
;	a5 - _custom
;	a6 - vars
;
ColorsSet:
			lea				palette(pc),a0
			movem.l			(a0),d0-d7
			lea				color(a5),a1
			movem.l			d0-d7,(a1)
			; second part of palette
			add.l			#32,a0
			add.l			#32,a1
			movem.l			(a0),d0-d7
			movem.l			d0-d7,(a1)
			rts

;-----------------------------------------------------------------------------
; in
;a5 - custom
; out
;a6 - vars variables
;
Init:
	;set screen hardware registers
			lea				pubScreenRegs(pc),a0
			moveq			#(pubScreenRegsEnd-pubScreenRegs)/4-1,d0
.setScreenRegs
			move.w			(a0)+,d1
			move.w			(a0)+,(a5,d1.w)
			dbf				d0,.setScreenRegs

	;for aga machines reset fmode and bplcon3
			move.w			#$2200,d0
			move.w			vposr(a5),d1
			and.w			d0,d1
			cmp.w			d0,d1
			bne.b			.makeCopper

			moveq			#0,d0
;		move.w	d0,fmode(a5)
;		move.w	d0,bplcon3(a5)

.makeCopper
			bsr.b			CopperMakeList

	;set copperlist
			move.l			copperList(a6),cop1lc(a5)
			move.w			#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER|DMAF_BLITTER|DMAF_SPRITE,dmacon(a5)

			rts

;-----------------------------------------------------------------------------
;in
;	a0 - copper
;	d0 - screen
;	a6 - vars
;out
;
CopperMakeList:
	;add bitplanes
			move.l			copperList(a6),a0
			moveq			#2,d1
			move.w			#bplpt,d2
			swap			d1
			move.l			screen(a6),d0
			moveq			#SCREEN_BPL-1,d3
			moveq			#SCREEN_BROW,d4
			swap			d2
.bloop		swap			d0
			move.w			d0,d2
			move.l			d2,(a0)+
			add.l			d1,d2
			swap			d0
			move.w			d0,d2
			move.l			d2,(a0)+
			add.l			d1,d2
			add.l			d4,d0
			dbf				d3,.bloop

			;add sprites - initially set all to dummy sprite
			move.l			a0,copperSprites(a6) ; note pointer

			moveq			#2,d1
			move.w			#sprpt,d2
			swap			d1
			move.l			spriteData(a6),d0
			moveq			#8-1,d3 ; num sprites
			moveq			#SPRITE_SIZE,d4 ; sprite size
			swap			d2
.sloop		swap			d0
			move.w			d0,d2
			move.l			d2,(a0)+
			add.l			d1,d2
			swap			d0
			move.w			d0,d2
			move.l			d2,(a0)+
			add.l			d1,d2
			;add.l			d4,d0
			dbf				d3,.sloop


	;add end copperlist
			moveq			#-2,d0
			move.l			d0,(a0)+

			rts

;-----------------------------------------------------------------------------

palette:
			dc.w			$0000,$022d,$0fb9,$0b23
			dc.w			$0ddf ; text color
			dc.w			$0666 ; logo color
			dc.w			$07ff,$07ff ; free
			dc.w			$0ff0,$0ff0,$0ff0,$0ff0,$0ff0,$0ff0,$0ff0,$0ff0 ; hero bitplane
			; sprite palettes
			INCLUDE			"assets/palette.inc"

pubScreenRegs:
			dc.w			color,0																		;black background
			dc.w			diwstrt,$2c81																;standard borders 
			dc.w			diwstop,$2cc1
			dc.w			ddfstrt,$0038
			dc.w			ddfstop,$00d0
			dc.w			bplcon0,SCREEN_BPL*$1000+$200
			dc.w			bplcon1,0
			dc.w			bplcon2,$24
			dc.w			bpl1mod,SCREEN_MODULO
			dc.w			bpl2mod,SCREEN_MODULO
			dc.w			spr+sd_ctl,0																;disarm mouse pointer sprite
pubScreenRegsEnd:

map:
; map data - tile numbers
			INCLUDE			"assets/map.inc"

return:
; return directions
			INCLUDE			"assets/return.inc"

rng:
			dc.b 0,2,0,2,3,2,3,2,3,0,3,1,1,3,2,3,0,0,0,0,3,1,1,3,1,3,2,2,1,1,0,2,1,3,2,2,2,1,0,0,3,3,0,0,1,3,2,2,3,1,1,2,1,0,3,0,1,2,2,0,1,0,3,0			

;-----------------------------------------------------------------------------
			SECTION			graphics,DATA_C

chipTiles:
; tile data - 16x8 in interlaved line order
			INCLUDE			"assets/tiles.inc"

chipSprites:
			INCLUDE			"assets/sprites.inc"

chipHero:
			INCLUDE			"assets/hero.inc"

chipFont:
			INCLUDE			"assets/font.inc"

chipLogo:
			INCLUDE			"assets/logo.inc"

;-----------------------------------------------------------------------------

			xref			Main
			xdef			chipData
			xdef			chipTiles
			xdef			chipSprites
			xdef			chipHero
			xdef			chipFont
			xdef			chipLogo
