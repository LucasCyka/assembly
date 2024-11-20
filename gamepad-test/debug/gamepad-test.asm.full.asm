
    #ORG 0x080000       ; Start after 512k (which are reserved for the OS)

    CALLR .Initialize   ; Setting up some things first
    
.MainLoop
    LD AB, 0x0200       ; Clear page 2 with transparent
	CALLR .ClearScreen
    LD AB, 0x0100       ; Clear page 1 with transparent
	CALLR .ClearScreen

    CALLR .GamepadsInputEvaluate    ; Get the input from gamepads
    CALLR .CheckIfUserWantsToExit   ; Exit to OS if user so commands
    JR Z, .Exit

    CALLR .DrawAllControllers       ; Draw the current state of the controllers

    JR .MainLoop                    ; And so on and on...

.Exit
    RET     ; Back to OS
; Handles gamepads input. Provides methods to get the state of all buttons/thumbs/triggers etc

.GamepadsInputUpdate
    PUSH A, Z
    
    ; Copy current state to the previous state buffer
    LD ABC, .gamepads_input_CSB
    LD DEF, .gamepads_input_PSB
    MEMC ABC, DEF, 41
    MEMF ABC, 41, 0         ; Clear the input buffer to not have rezidues

    ; Grab current state
    LD Z, 0x14              ; ReadGamePadsState, ABC already contains the target address
    INT 0x02, Z             ; Trigger interrupt `Input/Read GamePads State`

    POP A, Z
    RET

; checks whether any button on any controller is in down state
; output:   Z flag is set if true
.IsAnyButtonOnAnyControllerDown
    PUSH A, Z
    LD B, (.gamepads_input_CSB)
    AND B, 0b11110000
    CP B, 0
    INVF Z
    POP A, Z
    RET
	
; checks whether any button on controller 0 is in down state
; output:   Z flag is set if true
.IsAnyButtonOnController0Down
    PUSH A, Z
    LD B, (.gamepads_input_CSB)
    AND B, 0b00010000
    CP B, 0
    INVF Z
    POP A, Z
    RET

; checks whether a controller identified by its index is connected
; input:    A - the index of the controller to check connection on
; output:   Z flag is set if true
.IsControllerConnected
    PUSH A, Z
    LD B, (.gamepads_input_CSB)
    BIT B, A
    POP A, Z
    RET

; checks if button DPad Up is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadUpDown
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET
	
; checks if button DPad Up has just been pressed on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadUpPressed
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button DPad Down is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadDownDown
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET
	
; checks if button DPad Down has just been pressed on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadDownPressed
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button DPad Left is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadLeftDown
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button DPad Right is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadRightDown
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button A is in down state on specified controller
; input:    A - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonADown
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button A has just been pressed on specified controller
; input:    A - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonAPressed
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button B is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBDown
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET
	
; checks if button B has just been pressed on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBPressed
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button X is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonXDown
    PUSH A, Z
    LD X, 0b01000000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Y is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonYDown
    PUSH A, Z
    LD X, 0b10000000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing up on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingUp
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing down on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingDown
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing left on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingLeft
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing right on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingRight
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if right thumb joystick is pointing up on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbRightPointingUp
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if right thumb joystick is pointing down on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbRightPointingDown
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if right thumb joystick is pointing left on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbRightPointingLeft
    PUSH A, Z
    LD X, 0b01000000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if right thumb joystick is pointing right on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbRightPointingRight
    PUSH A, Z
    LD X, 0b10000000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button BigButton is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBigDown
    PUSH A, Z
    LD X, 0b01000000
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Back is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBackDown
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET
	
; checks if button Back has just been pressed on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBackPressed
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 3
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button Start is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonStartDown
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Right Trigger is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonRTDown
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Left Trigger is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonLTDown
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Left Button is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonLBDown
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Right Button is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonRBDown
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 3
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Left Thumbstick is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsLeftThumbPressed
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button Right Thumbstick is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsRightThumbPressed
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if any of A, B, X or Y is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsAnyABXYPressed
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if any DPad button is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsAnyDPadPressed
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if any L/R Shoulder button is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsAnyShoulderPressed
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if any L/R Trigger button is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsAnyTriggerPressed
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if the left thumbstick is moved in any direction on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsLeftThumbMoved
    PUSH A, Z
    LD X, 0b01000000
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if the right thumbstick is moved in any direction on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsRightThumbMoved
    PUSH A, Z
    LD X, 0b10000000
    LD Y, 4
    CALLR .is_state_button_down
    POP A, Z
    RET

; gets the value of Left Trigger
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetLeftTriggerValue
    PUSH A, Y
    LD Y, 5
    CALLR .get_state_value
    POP A, Y
    RET

; gets the value of Right Trigger
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetRightTriggerValue
    PUSH A, Y
    LD Y, 6
    CALLR .get_state_value
    POP A, Y
    RET

; gets the value of Left Thumb X
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetLeftThumbXValue
    PUSH A, Y
    LD Y, 7
    CALLR .get_state_value
    POP A, Y
    RET

; gets the value of Left Thumb Y
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetLeftThumbYValue
    PUSH A, Y
    LD Y, 8
    CALLR .get_state_value
    POP A, Y
    RET

; gets the value of Right Thumb X
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetRightThumbXValue
    PUSH A, Y
    LD Y, 9
    CALLR .get_state_value
    POP A, Y
    RET

; gets the value of Right Thumb Y
; input:    A register - the index of the controller to check button on
; output:   Z register - the requested value (signed)
.GetRightThumbYValue
    PUSH A, Y
    LD Y, 10
    CALLR .get_state_value
    POP A, Y
    RET


; ==================== Private utility functions ====================

; generic functionality that checks whether the bit pointed by the X
; register is set thereby indicating respective button is down
; input:    A contains the controller id (0 - 3)
;           X contains the binary sequence to point to button bit
; output:   Z flag is set if bit is set
.is_state_button_down
    LD BCD, .gamepads_input_CSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD A, (BCD)
    INV A
    AND A, X
    CP A, 0
    RET

; generic functionality that checks whether the bit pointed by the X
; register is set in current state but reset in previous thereby indicating
; respective button has just been pressed
; input:    A contains the controller id (0 - 3)
;           X contains the binary sequence to point to button bit
; output:   Z flag is set if bit is set
.is_state_button_pressed
    LD BCD, .gamepads_input_CSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD A, (BCD)
	INV A
    AND A, X
	ADD BCD, 41	; Add 41 bytes so we get to the "previous" buffer
	LD B, (BCD)
	AND B, X
	ADD A, B
    CP A, 0
    RET

; generic functionality that returns a specified value pointed at by
; the y register from the current state.
; input:    A register contains the controller id (0 - 3)
;           Y register contains the offset to the byte per controller state
; output:   Z register contains the return value
.get_state_value
    LD BCD, .gamepads_input_CSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD Z, (BCD)
    RET
	
; generic functionality that returns a specified value pointed at by
; the y register from the previous state.
; input:    A register contains the controller id (0 - 3)
;           Y register contains the offset to the byte per controller state
; output:   Z register contains the return value
.get_prev_state_value
    LD BCD, .gamepads_input_PSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD Z, (BCD)
    RET



; ==================== State buffers structure ====================

; - 1 connection and status byte:
; ANY[n] - is any button pressed on controller [n]
; CON[n] - is controller [n] connected
; Yes: 1, No: 0
;   b7  |    b6  |    b5  |    b4  |    b3  |    b2  |    b1  |    b0
;-----------------------------------------------------------------------
; ANY3  |  ANY2  |  ANY1  |  ANY0  |  CON3  |  CON2  |  CON1  |  CON0

; For each controller
; 10 bytes per controller (max 4 controllers) consisting of:

; - first byte for DPad + ABXY butons pressed:
;
;   b7  |    b6  |    b5  |    b4  |    b3  |    b2  |    b1  |    b0
;-----------------------------------------------------------------------
; Btn.Y |  Btn.X |  Btn.B |  Btn.A |DP.Right| DP.Left| DP.Down|  DP.Up

; - second byte for ThumbStick left and right. They register just the simple
; direction, without the progressive value:
;
;     b7    |      b6    |      b5    |      b4    |      b3    |      b2    |      b1    |      b0
;------------------------------------------------------------------------------------------------------
;TRght.Right| TRght.Left | TRght.Down |  TRght.Up  | TLft.Right |  TLft.Left |  TLft.Down |  TLft.Up

; - third byte for misc buttons:
; None means that no button is pressed, the inverse of "any button pressed"
;
;     b7    |      b6    |      b5    |      b4    |      b3    |      b2    |      b1    |      b0
;------------------------------------------------------------------------------------------------------
;    None   |  BigButton |     Back   |    Start   |  RTrigger  |  LTrigger  |  RShoulder |  LShoulder

; - fourth byte for left/right stick presses and misc flags
; b0:   Left stick is pressed
; b1:   Right stick is pressed
; b2:   Any of A, B, X, Y pressed
; b3:   Any of the DPad buttons pressed
; b4:   Any of L/R Shoulder pressed
; b5:   Any of L/R Trigger pressed
; b6:   Any left thumb direction actioned
; b7:   Any right thumb direction actioned

; - fifth byte contains the Left Trigger Z value (0 to 255)
; - sixth byte contains the Right Trigger Z value (0 to 255)
; - seventh byte contains the left thumb X value (-128 to 127)
; - eight byte contains the left thumb Y value (-128 to 127)
; - ninth byte contains the right thumb X value (-128 to 127)
; - tenth byte contains the right thumb Y value (-128 to 127)

.gamepads_input_CSB      ; current state buffer
    #DB [41] 0

.gamepads_input_PSB      ; previous state buffer
    #DB [41] 0

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

; This holds some preparatory methods ran at the start-up of the program to set things up

.Initialize
    LD A, 0x02 	                ; Interrupt selector, function "Set video pages count"
    LD B, 3 	                ; set video pages to 3.
    INT 0x01, A                 ; Execute interrupt 0x01 (Video) with function 0x02 (SetVideoPagesCount)
    
    LD AB, 0x000F               ; Clear page 0 with a solid color
	CALLR .ClearScreen
    CALLR .LoadFont
    CALLR .SetVideoAutoControlMode  ; We want to control when the drawing needs to be done
    CALLR .SetStaticText            ; Draw some static stuff
    CALLR .LoadSprites
    RET

; Loads font file to the .FontData pointer
.LoadFont
    LD A, 0x07				    ; Interrupt selector, function "File load"
    LD BCD, .FontFile           ; What is the font file path to load
    LD EFG, .FontData		    ; Deposit font at this address
    INT 0x04, A                 ; Execute interrupt 0x04 (filesystem) with function 0x30 (File load)
    RET

; Sets the video buffer mode to manual for all video pages
.SetVideoAutoControlMode
    LD A, 0x33
    LD B, 0b00000000
    INT 0x01, A
    RET

.SetStaticText
    CALLR .DrawTitleBar
    RET

; Loads the tilemap with all sprites
.LoadSprites
    LD A, 0x30                  ; Interrupt selector, function "Load image and palette"
    LD BCD, .TilemapFilePath    ; Address to where the path of the tilemap is located
    LD EFG, 0x85000;            ; Target address for the tilemap load
    INT 0x04, A                 ; Execute interrupt 0x4 (filesystem) with function 0x30 (Load image and palette)
    LD YZ, 0                    ; Since A contains the length of the palette in number of colors
    MUL ZA, 3                   ;   we use this trick to calculate the length of the palette in bytes
    SUB EFG, ZA                 ;   so we can localize where it is in memory. Remember, palette is loaded before the tilemap
    MEMC EFG, 0xFA0B40, YZA     ; Copy the palette to video page 1's palette
    MEMC EFG, 0xFA0840, YZA     ; ... and also to video page 2's palette
    RET

.GamepadsInputEvaluate
    CALLR .GamepadsInputUpdate              ; Update gamepad states
    CALLR .InputUpdate
    
    RET

; Using the keyboard input only to check the ESC key so we can exit
; Returns Z flag set if ESC pressed
.CheckIfUserWantsToExit
    LD A, 27				; Escape key code
    CALLR .InputKeyPressed
    CP A, 1
    RET
; Draws the controllers, buttons and represents their state
.DrawAllControllers
    LD A, 0                     ; Current controller index. This register must not be tainted along this loop

    CALLR .DrawProgramName      ; We draw the title. Since the DrawText draws on video page 2 that gets cleared often, we keep this here instead of drawing static (can be improved upon)
    CALLR .GetControllerNames   ; Gets the controller names from the interrupt and deposits them in memory for later

.next_controller_draw
    LD B, A                         ; We use B to help calculate the current controller drawing frame within the screen
    ADD B, B                        ; Multiply B by 2 since it will point to a 16-bit coordinate
    LD DEF, .controller_x_offset    ; Point to the X coordinate buffer
    ADD DEF, B                      ; Position ourselves to the correct X coordinate
    LD GH, (DEF)                    ; Load the X value in a 16-bit register
    LD (.spriteX), GH               ; ... so we can put it in a temporary place we know it's the X for our frame
    LD DEF, .controller_y_offset    ; Same here, point to the Y coordinate buffer
    ADD DEF, B                      ; Position ourselves to the correct Y coordinate
    LD GH, (DEF)                    ; Load the Y value in a 16-bit register
    LD (.spriteY), GH               ; ... so we can put it too in a temporary place we know it's the Y for our frame

    CALLR .IsControllerConnected    ; We determine if the current index has a controller connected
    JR NZ, .DrawInsertController        ; If not, we jump to draw the "INSERT CONTROLLER" message and continue the loop
    
    ; Draw a background for the controller name
    LD CDEF, 0xFFC70055             ; x, y
    LD GH, 236                      ; width
    LD IJ, 9                        ; height
    LD K, 3                         ; color
    CALLR .DrawRectangle

    CALLR .DrawCurrentControllerName    ; Draw the current controller name as reported by the information interrupt
    CALLR .DrawController               ; Draw the background controller sprite on top of which we'll be drawing buttons

; Starting here we'll basically check for every button/thumbstick/trigger to determine their state
; and depending on it we'll draw the representation of that state on top of the controller sprite
; at specified coordinates. This is a long and boring sequence.
    CALLR .IsButtonADown    ; A already contains the controller index
    JR NZ, .btn_A_not_pressed
    LD GHIJ, 0x000E0055     ; sprite x, y
    LD KLMN, 0x000B000C     ; sprite width, height
    LD PQ, 85   ; target x offset
    LD RS, 30   ; target y offset
    CALLR .DrawTile

.btn_A_not_pressed
    CALLR .IsButtonBDown    ; A already contains the controller index
    JR NZ, .btn_B_not_pressed
    LD GHIJ, 0x000E0055     ; sprite x, y
    LD KLMN, 0x000B000C     ; sprite width, height
    LD PQ, 94   ; target x offset
    LD RS, 22   ; target y offset
    CALLR .DrawTile

.btn_B_not_pressed
    CALLR .IsButtonXDown    ; A already contains the controller index
    JR NZ, .btn_X_not_pressed
    LD GHIJ, 0x000E0055     ; sprite x, y
    LD KLMN, 0x000B000C     ; sprite width, height
    LD PQ, 76   ; target x offset
    LD RS, 22   ; target y offset
    CALLR .DrawTile

.btn_X_not_pressed
    CALLR .IsButtonYDown    ; A already contains the controller index
    JR NZ, .btn_Y_not_pressed
    LD GHIJ, 0x000E0055     ; sprite x, y
    LD KLMN, 0x000B000C     ; sprite width, height
    LD PQ, 85   ; target x offset
    LD RS, 14   ; target y offset
    CALLR .DrawTile

.btn_Y_not_pressed
    CALLR .IsButtonDPadUpDown    ; A already contains the controller index
    JR NZ, .btn_DPUp_not_pressed
    LD GHIJ, 0x00440057     ; sprite x, y
    LD KLMN, 0x00080006     ; sprite width, height
    LD PQ, 39   ; target x offset
    LD RS, 36   ; target y offset
    CALLR .DrawTile

.btn_DPUp_not_pressed
    CALLR .IsButtonDPadDownDown    ; A already contains the controller index
    JR NZ, .btn_DPDown_not_pressed
    LD GHIJ, 0x00440064     ; sprite x, y
    LD KLMN, 0x00080006     ; sprite width, height
    LD PQ, 39   ; target x offset
    LD RS, 49   ; target y offset
    CALLR .DrawTile

.btn_DPDown_not_pressed
    CALLR .IsButtonDPadLeftDown    ; A already contains the controller index
    JR NZ, .btn_DPLeft_not_pressed
    LD GHIJ, 0x003E005D     ; sprite x, y
    LD KLMN, 0x00060007     ; sprite width, height
    LD PQ, 33   ; target x offset
    LD RS, 42   ; target y offset
    CALLR .DrawTile

.btn_DPLeft_not_pressed
    CALLR .IsButtonDPadRightDown    ; A already contains the controller index
    JR NZ, .btn_DPRight_not_pressed
    LD GHIJ, 0x004C005D     ; sprite x, y
    LD KLMN, 0x00060007     ; sprite width, height
    LD PQ, 47   ; target x offset
    LD RS, 42   ; target y offset
    CALLR .DrawTile

.btn_DPRight_not_pressed
    CALLR .IsButtonBigDown    ; A already contains the controller index
    JR NZ, .btn_big_not_pressed
    LD GHIJ, 0x00000055     ; sprite x, y
    LD KLMN, 0x000E000E     ; sprite width, height
    LD PQ, 53   ; target x offset
    LD RS, 14   ; target y offset
    CALLR .DrawTile

.btn_big_not_pressed
    CALLR .IsButtonBackDown    ; A already contains the controller index
    JR NZ, .btn_back_not_pressed
    LD GHIJ, 0x00190055     ; sprite x, y
    LD KLMN, 0x000A0004     ; sprite width, height
    LD PQ, 40   ; target x offset
    LD RS, 14   ; target y offset
    CALLR .DrawTile

.btn_back_not_pressed
    CALLR .IsButtonStartDown    ; A already contains the controller index
    JR NZ, .btn_start_not_pressed
    LD GHIJ, 0x00190055     ; sprite x, y
    LD KLMN, 0x000A0004     ; sprite width, height
    LD PQ, 70   ; target x offset
    LD RS, 14   ; target y offset
    CALLR .DrawTile

.btn_start_not_pressed
    CALLR .IsButtonLTDown    ; A already contains the controller index
    JR NZ, .btn_lt_not_pressed
    LD GHIJ, 0x00310057     ; sprite x, y
    LD KLMN, 0x00050002     ; sprite width, height
    LD PQ, 34   ; target x offset
    LD RS, 2   ; target y offset
    CALLR .DrawTile

.btn_lt_not_pressed
    CALLR .IsButtonRTDown    ; A already contains the controller index
    JR NZ, .btn_rt_not_pressed
    LD GHIJ, 0x00580057     ; sprite x, y
    LD KLMN, 0x00050003     ; sprite width, height
    LD PQ, 81   ; target x offset
    LD RS, 2   ; target y offset
    CALLR .DrawTile

.btn_rt_not_pressed
    CALLR .IsButtonLBDown    ; A already contains the controller index
    JR NZ, .btn_lb_not_pressed
    LD GHIJ, 0x00240059     ; sprite x, y
    LD KLMN, 0x00180009     ; sprite width, height
    LD PQ, 21   ; target x offset
    LD RS, 4   ; target y offset
    CALLR .DrawTile

.btn_lb_not_pressed
    CALLR .IsButtonRBDown    ; A already contains the controller index
    JR NZ, .btn_rb_not_pressed
    LD GHIJ, 0x0055005A     ; sprite x, y
    LD KLMN, 0x0018000A     ; sprite width, height
    LD PQ, 78   ; target x offset
    LD RS, 5   ; target y offset
    CALLR .DrawTile

.btn_rb_not_pressed
    LD F0, 5.1
    
; Draw left trigger value
    LD CDEF, 0x0000FFEB     ; x, y
    LD GH, 8                ; width
    LD IJ, 52               ; height
    LD K, 1                 ; color
    CALLR .DrawRectangle

    LD CDEF, 0x0001FFEC     ; x, y
    LD GH, 6                ; width
    LD IJ, 50               ; height
    LD K, 4                 ; color
    CALLR .DrawRectangle
    
    CALLR .GetLeftTriggerValue

    DIV Z, F0  ; Normalizes from (0 - 255) to (0 - 50)
    LD J, Z
    LD CDEF, 0x0001001E     ; x, y
    LD GH, 6                ; width
    LD K, 5                 ; color
    SUB EF, Z
    CALLR .DrawRectangle

; Draw right trigger value
    LD CDEF, 0x0070FFEB     ; x, y
    LD GH, 8                ; width
    LD IJ, 52
    LD K, 1                 ; color
    CALLR .DrawRectangle

    LD CDEF, 0x0071FFEC     ; x, y
    LD GH, 6                ; width
    LD IJ, 50
    LD K, 4                 ; color
    CALLR .DrawRectangle

    CALLR .GetRightTriggerValue

    DIV Z, F0  ; Normalizes from (0 - 255) to (0 - 50)
    LD J, Z
    LD CDEF, 0x0071001E     ; x, y
    LD GH, 6                ; width
    LD K, 5                 ; color
    SUB EF, Z
    CALLR .DrawRectangle

; Draw left thumb value

    LD CDEF, 0xFFC8FFEB     ; x, y
    LD GH, 53                ; width
    LD IJ, 53
    LD K, 1                 ; color
    CALLR .DrawRectangle

    LD CDEF, 0xFFC9FFEC     ; x, y
    LD GH, 51                ; width
    LD IJ, 51
    LD K, 4                 ; color
    CALLR .DrawRectangle

    CALLR .GetLeftThumbXValue
    DIV Z, F0
    LD (.left_thumb_x), Z                 ; Save leftX for later
    LD CD, 0xFFC7
    ADD CD, Z    
    CALLR .GetLeftThumbYValue
    DIV Z, F0
    LD (.left_thumb_y), Z                 ; Save leftY for later
    LD EF, 30
    SUB EF, Z

; Draw cross
    LD GH, 5                ; width
    LD J, 1                 ; height
    LD K, 5                 ; color
    CALLR .DrawRectangle

    LD GH, 1
    LD IJ, 5
    ADD CD, 2
    SUB EF, 2
    CALLR .DrawRectangle

; Draw right thumb value

    LD CDEF, 0x007C001E     ; x, y
    LD GH, 53                ; width
    LD IJ, 53
    LD K, 1                 ; color
    CALLR .DrawRectangle

    LD CDEF, 0x007D001F     ; x, y
    LD GH, 51                ; width
    LD IJ, 51
    LD K, 4                 ; color
    CALLR .DrawRectangle

    CALLR .GetRightThumbXValue
    DIV Z, F0
    LD (.right_thumb_x), Z                 ; Save leftX for later
    LD CD, 123
    ADD CD, Z    
    CALLR .GetRightThumbYValue
    DIV Z, F0
    LD (.right_thumb_y), Z                 ; Save leftX for later
    LD EF, 81
    SUB EF, Z

; Draw cross
    LD GH, 5                ; width
    LD J, 1                 ; height
    LD K, 5                 ; color
    CALLR .DrawRectangle

    LD GH, 1
    LD IJ, 5
    ADD CD, 2
    SUB EF, 2
    CALLR .DrawRectangle

; Display the thumbsticks depending on state
; Left thumbstick
    LD GH, 0
    CALLR .IsLeftThumbPressed
    JR NZ, .left_thumb_not_pressed
    INC H
    
.left_thumb_not_pressed
    RL H, 1
    CALLR .IsLeftThumbMoved
    JR NZ, .left_thumb_not_moved
    INC H
.left_thumb_not_moved
    MUL GH, 15      ; Sprite X
    LD IJ, 99       ; Sprite Y

    LD KLMN, 0x000F000F     ; sprite width, height
    LD PQ, 22   ; target x offset
    LD T, (.left_thumb_x)
    DIV T, 12
    ADD PQ, T
    LD RS, 22   ; target y offset
    LD T, (.left_thumb_y)
    DIV T, 12
    SUB RS, T

    CALLR .DrawTile

; Right thumbstick
    LD GH, 0
    CALLR .IsRightThumbPressed
    JR NZ, .right_thumb_not_pressed
    INC H
    
.right_thumb_not_pressed
    RL H, 1
    CALLR .IsRightThumbMoved
    JR NZ, .right_thumb_not_moved
    INC H
.right_thumb_not_moved
    MUL GH, 15      ; Sprite X
    LD IJ, 99       ; Sprite Y

    LD KLMN, 0x000F000F     ; sprite width, height
    LD PQ, 62   ; target x offset
    LD T, (.right_thumb_x)
    DIV T, 12
    ADD PQ, T
    LD RS, 39   ; target y offset
    LD T, (.right_thumb_y)
    DIV T, 12
    SUB RS, T

    CALLR .DrawTile
; Finished the boring job of displaying the state for current controller

.no_controller_draw
    INC A           ; We move to the next controller
    CP A, 4         ; ... but we check if this was the last one
    JR NZ, .next_controller_draw    ; ... if not, we continue

    VDL 0b00000111  ; Being done with drawing we signal that we want to manually draw video pages 0, 1 and 2
    RET

; Draws the "INSERT CONTROLLER" message which is yet another fancy sprite
.DrawInsertController
    LD GHIJ, 0x00000072     ; sprite x, y
    LD KLMN, 0x00790009     ; sprite width, height
    LD PQ, 1    ; target x offset
    LD RS, 32   ; target y offset
    CALLR .DrawTile
    JR .no_controller_draw  ; Since we jumped here, we continue jumping to continue the loop

; Draws the program name on the top bar
.DrawProgramName
    LD EFG, .program_name   ; text to draw
    LD HI, 1                ; x
    LD JK, 1                ; y
    CALLR .DrawText
    RET

; Draws the current controller name. Before calling this, a call to .GetControllerNames must be made
; This is not the most efficient way since we're calling .GetControllerNames everytime when we should only
; call it on new controller connected.
; input:    A register - the index that represents the current controller
.DrawCurrentControllerName
    PUSH A, Z
    LD B, A
    LD EFG, .ControllerNames        ; We point to the buffer where we loaded the controller names
.search_text
    CP B, 0                         ; If we landed on the current index to represent
    JR Z, .text_available           ; ... then we go to prepare coordinates and draw the text
    INC EFG                         ; otherwise, increment across the buffer
    CP (EFG), 0                     ; ... until we find the next zero string terminator
    JR NZ, .next                    ; if we didn't found the zero terminator, keep searching
    DEC B                           ; decrement the index pointer
    INC EFG                         ; increment one more time to jump over the terminator and land on printable text
.next
    JR .search_text                 ; repeat
.text_available
    LD HI, (.spriteX)               ; prepare the current frame X coordinate
    LD JK, (.spriteY)               ; and the Y coordinate
    SUB HI, 56                      ; Position X, Y relative to where we
    ADD JK, 86                      ; want to draw
    CALLR .DrawText                 ; Draw the found string which would be the controller name for the specified index
    POP A, Z
    RET

.DrawController
    PUSH A, Z
    LD A, 0x0E      ; Interrupt selector, function "Draw tile map sprite"
    LD BCD, 0x85000 ; Tilemap address
    LD EF, 121      ; Tilemap width
    LD GH, 0        ; Sprite x origin
    LD IJ, 0        ; Sprite y origin
    LD KL, 121      ; Sprite width
    LD MN, 85       ; Sprite height
    LD O, 1         ; Video page to draw to
    LD PQ, (.spriteX)   ; Specify current area coordinate X
    LD RS, (.spriteY)   ; Specify current area coordinate Y
    LD T, 0         ; No tile effects
    INT 0x01, A     ; Execute interrupt 0x01 (Video) with function 0x0E (Draw tile map sprite)
    POP A, Z
    RET

; Generic implementation that draws tiles on video page 2 (mostly dynamic tiles)
; Input:    GH and IJ - x and y of the sprite to draw as localized on the tilemap
;           KL and MN - width and height of the sprite to draw
;           PQ and RS - the x and y of where to draw the specified sprite
.DrawTile
    PUSH A, Z
    LD A, 0x0E      ; Interrupt selector, function "Draw tile map sprite"
    LD BCD, 0x85000 ; Tilemap address
    LD EF, 121      ; Tilemap width
    LD O, 2         ; Target video page
    ADD16 PQ, (.spriteX)    ; Adjust the relative offset of the current frame to the provided X
    ADD16 RS, (.spriteY)    ; ... and Y
    LD T, 0         ; No tile effects
    INT 0x01, A     ; Execute interrupt 0x01 (Video) with function 0x0E (Draw tile map sprite)
    POP A, Z
    RET

; Draws a rectangle
; Input:    CD and EF - x and y where to draw the rectangle
;           GH and IJ - the width and height of the rectangle
;           K will hold the color to draw the rectangle with
.DrawRectangle
    PUSH A, Z
    LD A, 0x06      ; Interrupt selector, function "Draw filled rectangle"
    LD B, 2         ; Target video page
    LD I, 0         ; IJ the height of the rectangle. Since we're working with small values, we can reset the I here and just play around with the provided J
    ADD16 CD, (.spriteX)    ; Again, adjust the relative offset of the current frame to the provided X
    ADD16 EF, (.spriteY)    ; ... and Y
    INT 0x01, A     ; Execute interrupt 0x01 (Video) with function 0x06 (Draw filled rectangle)
    POP A, Z
    RET

; Draw the title bar that's underneath the... title.
.DrawTitleBar
    PUSH A, Z
    LD A, 0x06      ; Interrupt selector, function "Draw filled rectangle"
    LD B, 0         ; Target video page
    LD GH, 480      ; The width of the title bar (in this case, full width)
    LD IJ, 8        ; IJ the height of the rectangle.
    LD K, 0x33      ; color of the title bar
    LD CD, 0        ; X position of the title bar
    LD EF, 0        ; Y position of the title bar
    INT 0x01, A     ; Execute interrupt 0x01 (Video) with function 0x06 (Draw filled rectangle)
    POP A, Z
    RET

; Draws a piece of text on the screen
; Input:    EFG - the address to the null terminates string that we want to draw
;           HI and JK - x and y of where to draw the text
.DrawText
    PUSH A, O
    LD A, 0x12					; Interrupt selector, function "Draw text"
    LD BCD, .FontData			; the source address (in RAM) of the font to be used.
    LD L, 1		                ; the color used to draw the string
    LD M, 2 	                ; the video page on which we draw the string
    LD NO, 233                  ; This will provide a horizontal limit for the text to draw. This limit is actually for the controller name
                                ; since that method also uses this and any other texts are shorter anyway
    INT 0x01, A					; Execute interrupt 0x01 (Video) with function 0x12 (Draw text)
    POP A, O
    RET

; Provides the controller names 
.GetControllerNames
    PUSH A, Z
    LD A, 0x16                  ; Interrupt selector, function "Read gamepads names"
    LD BCD, .ControllerNames    ; Where to deposit the names once retrieved
    INT 0x02, A                 ; Execute interrupt 0x02 (Input) with function 0x16 (Read gamepads names)
    POP A, Z
    RET

; Clears the specified video page with specified color
; Input:    A - the video page which needs clearing (0 - 7)
; Input:    B - the color which will be used to fill that memory page (0 - transparent or 1 - 255)
.ClearScreen
    PUSH Z
    LD Z, 0x05 	; ClearVideoPage
    INT 0x01, Z ; Trigger interrupt Video
    POP Z
    RET

; Here we start keeping some data either hardcoded, or some buffers to fill with data we obtain/calculate in realtime
.TilemapFilePath
    #DB "programs\gamepad-test\tiles\controller_tilesheet.png", 0

.PaletteSize
    #DB 0

.spriteX
    #DB 0x018A;

.spriteY
    #DB 0x00FF;

.controller_x_offset
    #DB 0x003C, 0x012C, 0x003C, 0x012C

.controller_y_offset
    #DB 0x0028, 0x0028, 0x00AF, 0x00AF

.left_thumb_x
    #DB 0x00

.left_thumb_y
    #DB 0x00

.right_thumb_x
    #DB 0x00

.right_thumb_y
    #DB 0x00

.program_name
    #DB "Gamepad test", 0

.FontFile
	#DB "fonts\SlickAntsContourSlim.font", 0

.FontData
	#DB [952] 0

.ControllerNames
	#DB [256] 0
    