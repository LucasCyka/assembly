#include ..\..\lib\c93-keyboard.asm

; Video fill test

	#ORG 0x080000

	LD Z, 10	; Some rectangle dimensions and limits
	LD M, 3
	LD B, 1
	LD CDEF, 0xFFA0FFA0	; x, y
	LD GH, 100
	LD IJ, 56
	LD K, 0xAB
.Repeat
	CALLR .InputUpdate
	LD A, 27				; Escape key
	CALLR .InputKeyPressed
	CP A, 1
	JR Z, .Exit
		
	LD A, 6
	INT 1, A	; DrawFilledRectangle at
				; subsequent registers coordinates
	
	LD NO, 380
	INT 3, M	; Random into register NO
	LD CD, NO
	LD NO, 210
	INT 3, M	; Random
	LD EF, NO
	
	LD K, 0
	INT 3, K	; Random again
	INC K
	CP Z, 0
	JP Z, .Skip
	DEC Z
	JP .Repeat
.Skip
	LD B, 0
	JP .Repeat
.Exit
	RET