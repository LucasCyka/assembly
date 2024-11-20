
    #ORG 0x100000

    LD F0, 0.0              ; u
    LD F7, 0.0267369595     ; r (tau/235)
    LD F8, 0.0              ; x
    LD F9, 0.0              ; y
    LD F10, 0.0             ; v
    LD F11, 0.0             ; t
    LD F12, 0.0             ; oldV

    LD A, 0x02  ; SetVideoPagesCount
    LD B, 1     ; number of pages (1-8)
    INT 0x01, A ; Trigger interrupt Video
    CALLR .ClearScreen
    CALLR .GeneratePalette

    ; Sets the video buffer control mode to manual
    LD A, 0x33
    LD B, 0b00000000
    INT 0x01, A

.Repeat

    CALLR .InputUpdate
    CALLR .InputNoStateChange
    CP A, 1
    JR Z, .no_key_input

    LD A, 27				; Escape key
    CALLR .InputKeyPressed
    CP A, 1
    JR Z, .exit

.no_key_input

    CALLR .ClearScreen
    
    LD A, 0     ; i
.Outer
    LD B, 0     ; j
.Inner
    LD F0, A    ; i
    ADD F0, F12 ; i + oldV
    LD F10, F0
    SIN F0      ; SIN(i+v)

    LD F1, F7
    MUL F1, A   ; r * i
    ADD F1, F8  ; r * i + x
    LD F2, F1   
    SIN F1      ; SIN(r * i + x)
    ADD F0, F1  ; u = SIN(i+v) + SIN(r*i+x)

    COS F10     ; COS(i+v)
    COS F2      ; COS(r*i+x)

    ADD F10, F2 ; v = COS(i+v) + COS(r*i+x)
    LD F12, F10 ; save v to oldV

    LD F8, F0
    ADD F8, F11 ; x = u + t

    ; Calculate the color to plot with
    LD R, A     ; i
    DIV R, 12   
    RL R, 4     ; set leftmost 4 bits as the red color determined by i
    LD S, B
    DIV S, 12
    OR R, S
    LD (.Color), R
    CALL .Plot

    INC B
    CP B, 192
    JR NZ, .Inner
    INC A
    CP A, 192
    JR NZ, .Outer

    ADD F11, 0.0015

    VDL 0b00000001  ; Manually draw the video frame to the render buffer

    JR .Repeat

.Plot
    PUSH A, Z

    LD A, 0x20
    LD B, 0     ; Video page
    MUL F0, 65.0
    LD CD, F0   ; x
    ADD CD, 240
    MUL F10, 65.0
    LD EF, F10  ; y
    ADD EF, 135
    LD G, (.Color)
    INT 0x01, A

    POP A, Z
    RET

.Color
    #DB 0x00

.ClearScreen
    PUSH A, Z
    LD A, 0
    LD B, 0     ; Black
    LD Z, 0x05 	; ClearVideoPage
    INT 0x01, Z ; Trigger interrupt Video
    POP A, Z
    RET

.GeneratePalette
    LD XYZ, 0xFE02C0    ; Palette address here

    LD24 (XYZ), 0     ; Pitch black
    ADD XYZ, 3
    LD I, 0
    LD J, 0
.NextColor
    LD R, I         ; Green index
    LD G, J
    MUL R, 12
    MUL G, 12
    LD (XYZ), R
    INC XYZ
    LD (XYZ), G
    INC XYZ
    LD (XYZ), 99
    INC XYZ
    INC I
    CP I, 16
    JR NZ, .NextColor
    LD I, 0
    INC J
    CP J, 16
    JR NZ, .NextColor
    RET

.exit
		RET

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
