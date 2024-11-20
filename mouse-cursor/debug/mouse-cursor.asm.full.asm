
; Sprite drawing. Given resolution is always 480 x 270, 8bpp

	#ORG 0x10000	; Code will be assembled at memory location 0x10000
	
.Restart
	
	CALLR .InputUpdate

	LD A, 27				; Escape key
	CALLR .InputKeyPressed
	CP A, 1
	JR Z, .exit
	

	LD D, 3		; Interrupt function selector 3
	INT 2, D	; Interrupt 2, function 3 (ReadMouseState)
				; Gets mouse x and y into EF and GH
				; (why EF and GH? Because they follow after the given D)

	CP GH, 270	; Lower mouse limit
	JR GT, .Restart	; If mouse y is greater than 270,
					; go back to ReadMouseState

	CP GH, 00	; Upper mouse limit
	JR LT, .Restart	; If mouse y is less than 20,
					; go back to ReadMouseState

	CP EF, 480	; Right-most mouse limit
	JR GT, .Restart	; If mouse x is greater than 460,
					; go back to ReadMouseState

	CP EF, 00	; Left-most mouse limit
	JR LT, .Restart	; If mouse x is less than 20,
					; go back to ReadMouseState

	
	; These 4 lines basically check whether the x, y are different
	; from the last coordinate used and if so, they prevent
	; redrawing
	CP MN, EF	
	JR NZ, .FoundDifferentXY
	CP OP, GH
	JR NZ, .FoundDifferentXY
	
	JR .Restart	; go back to ReadMouseState
.FoundDifferentXY
	
	LD MN, EF	; Save X to MN
	LD OP, GH	; Save y to OP

	LD W, 5		; Interrupt function selector 5: ClearVideoPage
	LD X, 0		; Video page to clear (0 - 8)
	LD Y, 0		; Color to clear with
	
	INT 1, W	; Trigger interrupt 1, function 5: Video/ClearVideoPage
	
	LD D, 0		; video page
	LD Z, 16	; Draw function
	LD ABC, .GfxData	; source of the icon data
	LD IJ, 7	; mouse icon width
	LD KL, 12	; mouse icon height
	INT 1, Z	; Trigger interrupt 1, function 16: DrawSprite
				; ABC contains the source icon, D the video page, EF, GH coords
				; IJ and KL contain the width and height
				
	JR .Restart	; Start over
.exit
	RET

	#ORG 0x20000
.GfxData	; The icon (1 byte per pixel, 7px x 12px icon)
	#DB 0xA6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	#DB 0xA6, 0xA6, 0x00, 0x00, 0x00, 0x00, 0x00
	#DB 0xA6, 0x15, 0xA6, 0x00, 0x00, 0x00, 0x00
	#DB 0xA6, 0x15, 0x15, 0xA6, 0x00, 0x00, 0x00
	#DB 0xA6, 0x15, 0x15, 0x15, 0xA6, 0x00, 0x00
	#DB 0xA6, 0x15, 0x15, 0x15, 0x15, 0xA6, 0x00
	#DB 0xA6, 0x15, 0x15, 0x15, 0x15, 0x15, 0xA6
	#DB 0xA6, 0x15, 0x15, 0x15, 0xA6, 0xA6, 0xA6
	#DB 0xA6, 0x15, 0xA6, 0x15, 0xA6, 0x00, 0x00
	#DB 0xA6, 0xA6, 0x00, 0xA6, 0x15, 0xA6, 0x00
	#DB 0x00, 0x00, 0x00, 0xA6, 0x15, 0xA6, 0x00
	#DB 0x00, 0x00, 0x00, 0x00, 0xA6, 0xA6, 0x00
	
; Handles keyboard input. Provides the following methods

; .InputUpdate: to continually update the state of the pressed keys
; .InputKeyPressed: determines whether given key has just been pressed
; .InputKeyReleased: determines whether given key has just been released
; .InputNoStateChange: determines if any key changed its state so you
;       can use this not to bother checking specific keys once you know this is true


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
; input: A - the keycode to look for
; output:A is 1 if true, 0 if false
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
    JR Z, .input_keyPressed_true
    LD A, 0
    RET

.input_keyPressed_true
    LD A, 1                 ; can be replaced with DEC A, kept it like this for readibility
    RET

; checks whether a key state has changed from pressed to not pressed. Indicates a key has been released
; input: A - the keycode to look for
; output:A is 1 if true, 0 if false
.InputKeyReleased
    ; expects key code in register A
    ; If current state is keyUp and previous state is keyDown
    PUSH B, Z

    CALLR .input_keyUp_current
    LD X, A
    CALLR .input_keyDown_previous
    ADD A, X
    POP B, Z
    CP A, 2
    JR Z, .input_keyReleased_true
    LD A, 0
    RET

.input_keyReleased_true
    LD A, 1                 ; can be replaced with DEC A, kept it like this for readibility
    RET

; Checks whether any key has been released or pressed by verifying the two states are identical
; Output: A is one if true, otherwise 0
; Note. This function's correct functionality relies on the fact that
; the current state buffer can NEVER be filled to the brim.
.InputNoStateChange
    PUSH B, Z

    LD ABC, .input_CSB
    LD DEF, .input_PSB

.input_no_state_change_loop
    CP (ABC), 0
    JR Z, .input_no_state_changed_true
    CP (ABC), (DEF)
    JR NZ, .input_no_state_change_false
    INC ABC
    INC DEF
    JR .input_no_state_change_loop

.input_no_state_change_false
    XOR A, A
    POP B, Z
    RET

.input_no_state_changed_true
    POP B, Z
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

.input_keyDown_current
    LD BCD, .input_CSB
    CALLR .input_keyDown
    RET

.input_keyDown_previous
    LD BCD, .input_PSB
    CALLR .input_keyDown
    RET

.input_keyUp_current
    LD BCD, .input_CSB
    CALLR .input_keyUp
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

.input_timings  ; milliseconds pressed (for future implementation)
    #DB [32] 0x0000
