#include ..\..\lib\c93-keyboard.asm

    #ORG 0x080000			; Start after 512k (which are reserved for the OS)

.Initialize
    LD A, 0x02 
    LD B, 1
	INT 0x01, A				; Number of video pages = 2
	
	LD A, 0x04
	LD B, 0
	INT 0x01, A				; Read palette starting address of video page 0
	LD (.Pal0Address), BCD
	
	LD A, 0x07
    LD BCD, .PalPath 
    LD EFG, (.Pal0Address)	    
	INT 0x04, A				; Load palette of sprites to video page 1
	
	LD BCD, .Spr1Path 
    LD EFG, .Spr1Buffer  
	INT 0x04, A				; Load sprite 1
	
	LD BCD, .Spr2Path 
    LD EFG, .Spr2Buffer  
	INT 0x04, A				; Load sprite 2
	
	; Sets the video buffer control mode to manual so we can update the video buffers 
    ; only when the scene is complete (with a VDL - video draw layers instruction)
    LD A, 0x33
    LD B, 0b00000000		; All layers to manual (0)
    INT 0x01, A				; Video interrupt
	

	
	LD ABC, 0x050000
	INT 0x01, A				; Clear video page 0

		  
	LD A, 0x10
	LD BCD, .Spr1Buffer
	LD E,0
	LD FG, 0
	LD HI, 0
	LD JK, (.Spr1Width)
	LD LM, (.Spr1Height)
	INT 0x01, A				; Draw sprite 1
	
	LD BCD, .Spr2Buffer
	LD HI, 100
	LD JK, (.Spr2Width)
	LD LM, (.Spr2Height)
	INT 0x01, A				; Draw sprite 2
	
	VDL 0b00000001 
    
.MainLoop

	; HandleInput
	
	CALLR .InputUpdate		; Get the updated key state

	LD A, 27				; Escape key
	CALLR .InputKeyPressed
	CP A, 1
	JR Z, .Exit

	LD A, 9
	LD B, 13
	CALLR .RotatePalette	; Rotate palete indices 9 - 13
	LD A, 24
	LD B, 31
	CALLR .RotatePalette	; Rotate palete indices 24 - 31
	VDL 0b00000001

	JR .MainLoop                    ; And so on and on...

.RotatePalette
; Rotate palette indices from A to B
	LD CDE, 3
	MUL DE, A
	ADD24 CDE, (.Pal0Address)
	LD IJK, 3
	ADD IJK, CDE
	LD OPQ, 3
	MUL PQ, B
	Add24 OPQ, (.Pal0Address)
	SUB B, A
	LD FGH, 3
	MUL GH, B
	LD LMN, (CDE)
	MEMC IJK, CDE, FGH
	LD (OPQ), LMN
	RET

.ChangeBGColour
	SUB B, 97
	MUL B, 3
	LD CDE, .BGColours
	ADD CDE, B
	LD FGH, (CDE)
	LD24 (.Pal0Address), FGH
	RET



.Exit
    RET     ; Back to OS

.Spr1Path
#DB "programs\Palette_Test\Sprite1.raw", 0
.Spr2Path
#DB "programs\Palette_Test\Sprite2.raw", 0
.PalPath
#DB "programs\Palette_Test\palette.pal", 0
.Spr1Width
#DB 0,50
.Spr1Height
#DB 0,60
.Spr2Width
#DB 0,40
.Spr2Height
#DB 0,40
.Spr1Buffer
#DB [3000] 0x00		; 50 x 60 = 3000
.Spr2Buffer
#DB [1600] 0x00		; 40 x 40 = 1600
.Pal0Address
#DB 0x000000
.Pal1Address
#DB 0x000000



