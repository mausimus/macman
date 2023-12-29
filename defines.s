; macman by mausimus (c) 2023
; mausimus.github.io
; MIT license
;

_custom				equ	$dff000
_ciaa				equ	$bfe001

; screen is 4 interlaved bitplanes, meaning they are arranged in memory line-per-line
; (1st line of 1st bitplane, 1st line of 2nd bitplane, etc.)
SCREEN_WIDTH		=	320
SCREEN_HEIGHT		=	256
SCREEN_BPL			=	4
SCREEN_BROW			=	SCREEN_WIDTH/8
SCREEN_LINE			=	SCREEN_BROW*SCREEN_BPL

; background tiles are 8x8
MAP_W				=	28
MAP_H				=	31
MAP_TILE_SIZE		=	8
MAP_COL_STEP		=	MAP_TILE_SIZE/8
MAP_ROW_SIZE		=	SCREEN_WIDTH*2*SCREEN_BPL/(16/MAP_TILE_SIZE)
MAP_ROW_STEP		=	MAP_ROW_SIZE-(MAP_W*MAP_COL_STEP)
HERO_SIZE			=	16
FONT_SIZE		    =	8
SPRITE_SIZE			=	18*4

SCREEN_MODULO		=	(SCREEN_BPL-1)*SCREEN_BROW
SCREEN_MEMSIZE		=	SCREEN_LINE*SCREEN_HEIGHT
COPPER_MEMSIZE		=	(SCREEN_BPL*2+1)*4+(8*2*4)	; sprites

CHIPDATA_MEMSIZE	=	SCREEN_MEMSIZE+COPPER_MEMSIZE

NUM_SPRITES			=	4
SPRITE_FRAMES       =   16

DEATH_TIME          =   50
PELLET_TIME         =   (50*10)
PELLET_ALERT         =  (50*2)
GHOST_POINTS        =   200
BASE_POINTS         =   10
PELLET_POINTS       =   40

; object struct offsets
OBJ_X				=	0
OBJ_Y				=	2
OBJ_D				=	4 ; direction
OBJ_F				=	6 ; frame no
OBJ_S				=	8 ; state
OBJ_SIZE			=	10

;-----------------------------------------------------------------------------

WAIT_BEAM:     MACRO
               lea             vposr(a5),a0
.1\@           moveq           #1,d0
               and.w           (a0),d0
               bne.b           .1\@
.2\@           moveq           #1,d0
               and.w           (a0),d0
               beq.b           .2\@
               ENDM

;-----------------------------------------------------------------------------
WAIT_BLITTER:  MACRO

               tst.b           dmaconr(a5)
.1\@           btst            #6,dmaconr(a5)
               bne             .1\@
               ENDM

;-----------------------------------------------------------------------------

GET_HERO:       MACRO
                move.l			a6,a0
                add.l			#hero,a0
                ENDM

;-----------------------------------------------------------------------------

GET_GHOSTS:     MACRO
                move.l			a6,a0
                add.l			#ghosts,a0
                ENDM
