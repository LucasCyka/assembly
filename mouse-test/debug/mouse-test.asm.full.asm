
; Some silly "crayon" drawing tool

		#ORG 0x80000

		CALLR .InitVideo
		LD K, 0xAA				; Point color
.Loop
		CALLR .InputUpdate
		CALLR .InputNoStateChange
		CP A, 1
		JR Z, .no_key_input

		LD A, 27				; Escape key
		CALLR .InputKeyPressed
		CP A, 1
		JR Z, .exit

.no_key_input
		CALLR .HandleMouseDraw
		JR .Loop
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

; Provides some custom palettes you can use.
; If adding a palette, consider sorting it from light to dark:
; https://elektrobild.org/tools/sort-colors

; Source: https://lospec.com/palette-list/lost-century
.Palette16_lost_century
		#DB 0xD2C9A5, 0xD1B187, 0x8CABA1, 0xAB9B8E, 0xBA9158, 0xB3A555, 0xC77B58, 0x847875
		#DB 0xAE5D40, 0x927441, 0x4B726E, 0x77743B, 0x79444A, 0x574852, 0x4B3D44, 0x4D4539

; Source: https://lospec.com/palette-list/fantasy-kitchen-16
.Palette16_fantasy_kitchen
		#DB 0xFFFFF5, 0xE2D9EA, 0xEACEBD, 0xFFCE95, 0xF2A65E, 0xB48894, 0x8C88A5, 0xBA6156
		#DB 0x10D275, 0x636686, 0x8D2D4E, 0x007899, 0x5A265E, 0x473B78, 0x323E4F, 0x120E23

; Source: https://lospec.com/palette-list/steam-lords
.Palette16_steam_lords
		#DB 0xC0D1CC, 0xA0B9BA, 0xA19F7C, 0x7C94A1, 0x65738C, 0x77744F, 0x775C4F, 0x4F7754
		#DB 0x4F5277, 0x3A604A, 0x603B3A, 0x433A60, 0x3B2137, 0x2F213B, 0x213B25, 0x170E19

; Source: https://lospec.com/palette-list/bubblegum-16
.Palette16_bubblegum
		#DB 0xFAFDFF, 0xFF80A4, 0xBFFF3C, 0xFF2674, 0x68AED4, 0xFFD100, 0xFF8426, 0x10D275
		#DB 0x94216A, 0xD62411, 0x007899, 0x234975, 0x7F0622, 0x430067, 0x002859, 0x16171A

; Source: https://lospec.com/palette-list/fading-16
.Palette16_fading
		#DB 0xDDCF99, 0xA99C8D, 0xCCA87B, 0x8E9F7D, 0xAAA25D, 0xA88A5E, 0x8C7C79, 0xB97A60
		#DB 0x7D7B62, 0x5B7D73, 0x846D59, 0x9C524E, 0x645355, 0x4E5463, 0x774251, 0x4B3D44

; Source: https://lospec.com/palette-list/microsoft-windows
.Palette16_microsoft_windows
		#DB 0xFFFFFF, 0xBEBEBE, 0x06FFFF, 0xFFFF04, 0x06FF04, 0x7E7E7E, 0xFE00FF, 0x7E7E00
		#DB 0x047E7E, 0xFE0000, 0x047E00, 0x7E007E, 0x0000FF, 0x7E0000, 0x00007E, 0x000000

; Source: https://lospec.com/palette-list/commodore64
.Palette16_commodore_64
		#DB 0xFFFFFF, 0xADADAD, 0xC9D487, 0x9AE29B, 0x6ABFC6, 0x898989, 0xCB7E75, 0x5CAB5E
		#DB 0x887ECB, 0xA1683C, 0x626262, 0xA057A3, 0x9F4E44, 0x6D5412, 0x50459B, 0x000000

; Source: https://lospec.com/palette-list/sweetie-16
.Palette16_sweetie
		#DB 0xF4F4F4, 0x94B0C2, 0x73EFF7, 0xFFCD75, 0xA7F070, 0x41A6F6, 0x38B764, 0xEF7D57
		#DB 0x566C86, 0x257179, 0xB13E53, 0x3B5DC9, 0x333C57, 0x5D275D, 0x29366F, 0x1A1C2C

; Source: https://lospec.com/palette-list/swordp
.Palette_swordp
		#DB 0xD7EDF6, 0xB8B8B8, 0xA7D9EA, 0x989898, 0x689BAC, 0xD37979, 0xC88124, 0x6B6B6B
		#DB 0xBF4141, 0x87591A, 0x225F74, 0xAB2626, 0x813D3D, 0x434343, 0x614115, 0x4D2C00




.InitVideo
		LD A, 0x02 	; SetVideoPagesCount interrupt
		LD B, 3 	; set video pages to 3.
		INT 0x01, A ; Trigger interrupt Video with SetVideoPagesCount
		CALLR .SetPalettes

        RET

.SetPalettes
		LD EFG, 48			; We'll copy 16 colors multiplied by 3 bytes for R, G and B
		LD HIJ, .Palette16_bubblegum	; Point to where we store the palette

		LD A, 0x04 	; ReadVideoPaletteAddress
		LD B, 2 	; the video page
		INT 0x01, A ; Trigger interrupt Video

		ADD BCD, 3	; First color is transparent for all video pages except the first
		MEMC HIJ, BCD, EFG

		LD KLM, BCD

		LD B, 1 	; Get palette for video page 1
		INT 0x01, A ; Trigger interrupt Video

		ADD BCD, 3	; First color is transparent for all video pages except the first
		MEMC HIJ, BCD, EFG

		LD NOP, BCD

		LD B, 0		; Get palette for video page 0
		INT 0x01, A ; Trigger interrupt Video

		ADD BCD, 3	; We still place the colors offset to maintain the same color codes across pages
		MEMC HIJ, BCD, EFG

		LD QRS, BCD

		RET

.HandleMouseDraw
		LD A, 1					; Clear the dot cursor page
		LD B, 0					; Clear with transparent
		CALLR .ClearScreen

		LD XYZ, 480
		LD D, 3					; set "Read mouse state" mode
		INT 2, D				; Trigger Read mouse state interrupt
		MUL XYZ, GH				; y position
		ADD XYZ, EF				; x position
		LD ABC, (.VideoPage2Pointer)		; Video memory pointer to where we draw
		LD MNO, (.VideoPage1Pointer)		; Video memory pointer to where we show the dot cursor
		ADD ABC, XYZ
		ADD MNO, XYZ
		LD (MNO), K

		CP I, 1					; mouse button state

		JR NZ, .draw_pixel_exit
		LD (ABC), K				; Put pixel on screen if mouse lButton is pressed
.draw_pixel_exit
		RET

; Clears the specified video page with specified color
; input A: the video page which needs clearing (1-8)
; input B: the color which will be used to fill that memory page (0 - transparent or 1 - 255).
.ClearScreen
		PUSH Z
		LD Z, 0x05 	; ClearVideoPage
		INT 0x01, Z ; Trigger interrupt Video
		POP Z
		RET

.VideoPage1Pointer
		#DB 0xFC0B80

.VideoPage2Pointer
		#DB 0xFA1140

.PointVideoOffset
		#DB 0x000000