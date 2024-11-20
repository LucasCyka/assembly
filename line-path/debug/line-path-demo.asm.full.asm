
	#ORG 80000

	LD A, 0x05     			; ClearVideoPage
	LD B, 0x00     			; the video page which needs clearing (0 - 7)
	LD C, 0x00     			; the color which will be used to fill that memory page (0 - transparent or 1 - 255).
	INT 0x01, A       		; Trigger interrupt Video

	LD A, 0x24     			; LinePath
	LD BCD, .Points     	; the RAM address where the points are stored.
	LD E, 0x00     			; the video page on which we draw (0 - 7)
	LD F, 0xAA     			; the fill color of the ellipse.
	INT 0x01, A       		; Trigger interrupt Video

.Repeat
	CALLR .InputUpdate
	LD A, 27				; Escape key
	CALLR .InputKeyPressed
	RETIF Z
	JR .Repeat

; Keyboard handling routines:

; Moves the current state to a previous state then captures the current state.
; Used by [] to determine whether specific keys have just been pressed or released.
; This should be run continuously in a main loop. Recommended: 60 times per second at most.
.InputUpdate
    PUSH A, Z

    ; Copy current state to the previous state buffer
    LD ABC, .input_CSB
    LD DEF, .input_PSB
    MEMC ABC, DEF, 32
    MEMF ABC, 32, 0         ; Clear the input buffer to not have rezidues

    ; Grab current state
    LD Z, 0x10              ; ReadKeyboardPressedKeysAsCodes, ABC already contains the target address
    INT 0x02, Z             ; Trigger interrupt `Input/Read Keyboard Pressed Keys As Codes`

    POP A, Z
    RET

; checks whether a key state has changed from not pressed to pressed. Indicates a key has been pressed
; input:    A - the keycode to look for
; output:   Z flag is set if true
.InputKeyPressed
    ; expects key code in register A
    ; if current state is keyDown and previous state is keyUp
    PUSH B, Z
    
    CALLR .input_keyDown_current
    LD X, A
    CALLR .input_keyUp_previous
    ADD A, X
    
    POP B, Z
    
    CP A, 2
    RET

.input_keyDown_current
    LD BCD, .input_CSB
    CALLR .input_keyDown
    RET

.input_keyDown_previous
    LD BCD, .input_PSB
    CALLR .input_keyDown
    RET

; whether the state of key code received in A is keyDown (exists in the indicated buffer)
; input: A - the keycode to look for
; input: BCD - the address of the buffer to search
; output:A is 1 if true, 0 if false
.input_keyDown              
    PUSH E, Z
    LD EF, 32

.input_keyDown_next
    LD X, (BCD)
    CP X, A
    JR Z, .input_keyDown_true
    DEC EF
    INC BCD
    CP EF, 0
    JR NZ, .input_keyDown_next
    POP E, Z
    XOR A, A
    RET

.input_keyDown_true
    POP E, Z
    LD A, 1
    RET

; whether the state of key code received in A is keyUp (missing from the indicated buffer)
; input: A - the keycode to look for
; input: BCD - the address of the buffer to search
; output:A is 1 if true, 0 if false
.input_keyUp
    CALLR .input_keyDown
    CP A, 0
    JR Z, .input_keyUp_true
    LD A, 0
    RET

.input_keyUp_true
    LD A, 1
    RET

.input_keyUp_previous
    LD BCD, .input_PSB
    CALLR .input_keyUp
    RET

; Buffers
.input_CSB      ; current state buffer
    #DB [32] 0

.input_PSB      ; previous state buffer
    #DB [32] 0
; Points that draw a test geometrical figure

.Points
	#DB 0x0080, 0x0020 ; Start at top middle
	#DB 0x0090, 0x0030 ; Move to top right
	#DB 0x00A0, 0x0020 ; Right upper peak
	#DB 0x00B0, 0x0030 ; Right mid
	#DB 0x00A0, 0x0040 ; Back in, upper right inner corner
	#DB 0x00C0, 0x0060 ; Right outer mid
	#DB 0x00A0, 0x0080 ; Lower right peak
	#DB 0x00B0, 0x0090 ; Lower right outside
	#DB 0x00A0, 0x00A0 ; Lower right inner
	#DB 0x0080, 0x00C0 ; Bottom middle
	#DB 0x0060, 0x00A0 ; Lower left inner
	#DB 0x0050, 0x0090 ; Lower left outside
	#DB 0x0060, 0x0080 ; Lower left peak
	#DB 0x0040, 0x0060 ; Left outer mid
	#DB 0x0060, 0x0040 ; Back in, upper left inner corner
	#DB 0x0050, 0x0030 ; Left mid
	#DB 0x0060, 0x0020 ; Left upper peak
	#DB 0x0070, 0x0030 ; Top left
	#DB 0x0080, 0x0020 ; Back to top middle
	#DB 0x0090, 0x0050 ; Intersecting line to right
	#DB 0x0070, 0x0050 ; Across to left
	#DB 0x0070, 0x0070 ; Down to lower left inner corner
	#DB 0x0090, 0x0070 ; Across to lower right inner corner
	#DB 0x0090, 0x0050 ; Back up to start of intersecting line
	#DB 0x0080, 0x0020 ; End back at top middle
	#DB 0x0080, 0x0020 ; End