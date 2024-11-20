; The isometric tileset used with this demo has been designed by NullDreams
; please visit his page to see his more of his work here: https://nulldreams.itch.io

; This program exemplifies how you can load different 8 bit palette based PNG files with different color palettes and merge those into one of the
; video palettes that's meant to draw them. The usecase for such a situation is when you have some fixed tileset you need to render on the same
; layer as other tiles that can change depending on the level. As such, to not overflow the palette capacity you would slice the tiles on themes
; pertaining to each individual level and merge them using this mechanism each time you move to a different game level.


    #ORG 0x80000                    ; We position our code outside the OS reserved area of 512k
    
    CALLR .InitializeGFX            ; Set video mode, load background and tiles

    VDL 0b00000001                  ; Signal to manually refresh first video page (first bit is set) since InitializeGFX
                                    ; already loads the backgound in memory for video page 1. Alternatively, the VDL below can
                                    ; be modified to do this refresh by changing it to VDL 00000011, but since the background
                                    ; never changes, it suffices to do it once here.

    CALLR .InitializeClock          ; Initialize the clock time
    LD (.zOffset), 0                ; This will be used to manage an oscilator used to sustain the main animation


.Repeat                             ; Main loop
    CALL .HasUpdateTimePassed       ; Updates the clock and also returns whether it passed the target frame time
    JR NZ, .Repeat                  ; We loop back until the allowed timeframe is reached

    CALLR .InputUpdate              ; Update the keyboard input buffers to be able to determine changes
    ADD (.zOffset), 7               ; Controls the speed of the animation. Higher values -> faster  (default 7)

	LD A, 27				        ; Escape key
	CALLR .InputKeyPressed          ; Check if the keycode in A has just been pressed
	RETIF Z                         ; Exit if pressed

    CALLR .Redraw                   ; Redraw whole scene

    JR .Repeat

.Redraw
    CALLR .ClearActivePage          ; Clear the layer where the active drawing takes place
    CALLR .DrawScene                ; Draw tiles

    VDL 0b00000010                  ; Signal to manually refresh second video page (second bit is set)
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
    LD Z, A
    
    CALLR .input_keyDown_current
    LD X, A

    LD A, Z
    CALLR .input_keyUp_previous
    ADD A, X
    
    POP B, Z
    
    CP A, 2
    RET

; checks whether a key state has changed from pressed to not pressed. Indicates a key has been released
; input: A - the keycode to look for
; output:A is 1 if true, 0 if false
.InputKeyReleased
    ; expects key code in register A
    ; If current state is keyUp and previous state is keyDown
    PUSH B, Z
    LD Z, A

    CALLR .input_keyUp_current
    LD X, A

    LD A, Z
    CALLR .input_keyDown_previous
    ADD A, X
    POP B, Z
    CP A, 2
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

; Functionality related to graphics

.InitializeGFX

    CALLR .SetVideoAutoControlMode  ; Set the video mode so we can control WHEN we actually draw on the screen with VDL

    LD A, 0x02              ; SetVideoPagesCount
    LD B, 3                 ; set 3 video pages
    INT 0x01, A             ; Trigger interrupt Video with function SetVideoPagesCount

    ; The functionality of clearing the active (second) video page has been moved to a dedicated function since
    ; this is called every frame render.
    CALLR .ClearActivePage
    INC B                   ; .. since the function above sets the necessary data, we simply increment and clear the next page also
    INT 0x01, A             ; Clear third video page

    ; Obtain the memory location of the palette belonging to the first video page, the one that will render the background
    LD W, 0x04              ; ReadVideoPaletteAddress
    LD X, 0                 ; the video page palette of which start address we need to find (0 - 7)
    INT 0x01, W             ; Trigger interrupt Video with function ReadVideoPaletteAddress
    ; XYZ now contains the pointer to layer 0's palette address

    ; Loading background directly in the video buffer. This can be done this way since the width
    ; of the image to be loaded matches the width of the video frame. If this would have not been the
    ; case, the proper way is to load in memory and then draw them with DrawSprite (int 0x01, fn 0x10)
    LD A, 0x33
    LD BCD, .PathBackground
    LD EFG, XYZ             ; Load the palette directly to video layer 0's palette
    LD HIJ, 0xFE05C0        ; Load the image data directly into the video buffer since it matches the w/h
    INT 0x04, A

    ; We repeat this process for the second video page that will actually draw the tiles since we need to load the palettes
    ; obtained from the png tilesets.
    LD W, 0x04              ; ReadVideoPaletteAddress
    LD X, 1                 ; the video page palette of which start address we need to find (0 - 7)
    INT 0x01, W             ; Trigger interrupt Video with function ReadVideoPaletteAddress
    ; XYZ now contains the pointer to layer 1's palette address

    ; Load the tiles pngs. This is a more complicated way of doing things. All tiles could fit nicely in one single tileset, but for the sake of
    ; demonstrating how merging works, we are going to load two tilesets with two different transparency keys and have them merged in second
    ; video layer's palette.

    ; Load the first tileset
    LD A, 0x34              ; Load8BitPngWithCustomTransparency
    LD BCD, .PathTilesA     ; the source address (in RAM) of the null terminated string which represents the desired path to the image file to be processed.
    LD EFG, XYZ             ; the pointer to the address (in RAM) where the PNG palette and transparency data will be loaded.
    LD HIJ, .TilesAData     ; the pointer to the address (in RAM) where the PNG pixel data will be loaded.
    LD KLMN, 0              ; the RGBA color that will be interpreted as the transparent color from the provided RGB.
    INT 0x04, A             ; Trigger interrupt Filesystem
    
    LD H, F                 ; Transfer the number of loaded palette colors to register H used with the interrupt below since we need that for the merging process

    ; Load the second tileset as merged to the first
    LD A, 0x36              ; Merge8BitPngWithCustomTransparency
    LD BCD, .PathTilesB     ; the source address (in RAM) of the null terminated string which represents the desired path to the image file to be processed.
    LD EFG, XYZ             ; the pointer to the address (in RAM) where the PNG palette and transparency data will be loaded.
    ; H already contains the number of existing colors on the color palette that will be merged into.
    LD IJK, .TilesBData     ; the pointer to the address (in RAM) where the PNG pixel data will be loaded.
    LD LMNO, 0xFF00FFFF     ; the RGBA color that will be interpreted as the transparent color from the provided RGB.
    INT 0x04, A             ; Trigger interrupt Filesystem

    RET


; Sets the video buffer mode to manual for all video pages
.SetVideoAutoControlMode
    LD A, 0x33
    LD B, 0b00000000
    INT 0x01, A
    RET


; Drawing the actual tiles on the second video layer, above the background.
; X and Y below represent the isometric coordinates. They will be later converted to cartesian coordinates.
.DrawScene
    LD Y, 0                     ; Start on vertical with the top row
.NextY
    LD X, 0                     ; Start on horizontal
.NextX
    LD UV, 0                    ; Here we're picking up the tile index from the .TerrainLayout defined below. To do that, we're
    LD W, Y                     ; converting the X and Y into a linear index. Since Y moves on isometric vertical,
    MUL UVW, 10                 ; we multiply it with 10 to land on the correct row, then
    ADD UVW, X                  ; we add X to the result so we can land on the correct tile.
    ADD24 UVW, .TerrainLayout   ; Now we have an index that needs to be added to the .TerrainLayout address offset
    LD W, (UVW)                 ; and getting the byte from that address lands us with the correct tile to place at this X, Y.

    CALLR .DrawSpriteIndex      ; We draw the sprite with the index stored in W
    INC X                       ; We move to the next tile on the horizontal
    CP X, 10                    ; until we reach the end
    JR NZ, .NextX
    INC Y                       ; ... then we move to the next row
    CP Y, 10                    ; until that's also finished
    JR NZ, .NextY

    RET


; Accepts sprinte index in register W, draws to layer 1
.DrawSpriteIndex
    PUSH A, Z               ; Preserving the registers since we have an enclosing loop that uses some of them
    LD I, 0
    LD J, W                 ; IJ will have the value of W (that itself can be anything from 0 to 15)
    DIV IJ, 4, GH           ; since the tileset is organized over a 4 x 4 pattern, we get IJ (the Y on the tilesheet) as the result of division by 4
                            ; and the remainder of that into GH (which will be the X)

    MUL GH, 32              ; Since each tile is 32 pixels wide, we multiply the X obtained above by this number
    MUL IJ, 24              ; ... and since the height is 24, we do the same for Y effectively getting to the top left pixel of the sprite to draw

    ; Convert isometric coordinates to cartesian coordinates
    LD Z, Y
    LD Y, 9                 ; 10 is the maximum row width in isometric space, so that's 0-9 (10 items)
    SUB Y, Z                ; Reverse the X coordinate so we can draw in the correct Z order

    ; This below transforms the X, Y of the isometric grid into the X, Y of the rendering layer. The formulas were obtained by drawing an isometric grid on paper,
    ; obtaining the actual coordinates by trial-error, observing the pattern and determing the formulas below which sit above their respective implementations
    ; however, a bit different, probably from the way I drew the coordinates at a larger step on the math paper.
    
    ; Compute cartesian X. Original formula is Xs = 2*(Xi + Yi + 2) * 32px
    LD PQ, 2
    ADD PQ, X
    ADD PQ, Y
    MUL PQ, 16

    ; Compute cartesian Y. Original formula is Ys = (8 + Xi - Yi) * 24px
    LD RS, 8
    ADD RS, X
    SUB RS, Y
    MUL RS, 8
    
    ; Defining interrupt input
    LD A, 0x0E              ; DrawTileMapSprite function index
    LD BCD, .TilesAData     ; the source address (in RAM) of the tile map. Since the two tile sheets are conveniently one right after another
                            ; we can access them both just by playing with the coordinates
    LD EF, 128              ; the width of the tilemap in pixels. This is used by the drawtilemapsprite interrupt to understand when's the next row of pixels
                            ; so it can travel vertically for its next sprite's row
    ; GH and IJ (x and y) are already set from the index
    LD KL, 32               ; the width of the sprite within the tile map.
    LD MN, 24               ; the height of the sprite within the tile map.
    LD O, 1                 ; the target video page where the sprite is to be drawn.

    ADD PQ, 52              ; Add an arbitrary offset to the X so it centers the scene horizontally
    ADD RS, 59              ; Add an arbitrary offset to the Y so it centers the scene vertically

    LD Z, (.zOffset)        ; Taking an always-incrementing offset to obtain an oscilation
    LD W, X                 ; We involve both isometric X and Y at higher magnitude so we can
    MUL W, 10               ; get the "wave" effect on a diagonal. We could restrict to either X or Y and the wave
    ADD Z, W                ; will simply follow that path only. Therefore, we add both X and Y with a higher
    LD W, Y                 ; magnitude to Z, which is the offset.
    MUL W, 16
    ADD Z, W                ; Then we call the function that gets us the oscillation based on the provided value.
    CALLR .GetOscillation   ; This function is meant to yield smooth ending values even if the byte input is restarted
    DIV Z, 16               ; The result is placed back in Z and we make it smaller so the effect is more subtle
    ADD RS, Z               ; We now add the displacement result to RS which is (as seen above) the cartesian Y coordinate
    LD T, 0b00000000        ; reset effect bits. Bit 0 - flip horizontal, bit 1 - flip vertical. The rest of the bits are not used.
    INT 0x01, A             ; Trigger interrupt Video with the function index stored in A to draw the tile

    POP A, Z                ; We return the previous values to registers before
    RET                     ; exiting back to the loop

.ClearActivePage
    LD A, 0x05              ; ClearVideoPage function index
    LD B, 1                 ; Clear second video page
    LD C, 0                 ; the color which will be used to fill that memory page (0 - transparent).
    INT 0x01, A             ; Trigger interrupt Video with the function index stored in A to clear the page

    RET


; This will hold a value that will be incremented each frame by 1 until 255 then it will start over from 0.
; It will be further processed by GetOscillation to transform it into a range of 0, 2, ..., 252, 254, 252, ... 2, 0
; which will represent a linear oscilation.
.zOffset
    #DB 0x00

; Some demo tiles layout. Each cell must take values from 0x00 to 0x0F
; If any value specified here is outside this range, the program will not break, however, it will interpret as image whatever it finds in memory
; outside the bounds of the coherent image and you'll get either some noisy artifacts or if the memory reached is filled with zeroes, nothing visible at all
; since zeroes mean transparent colors for all layers except the first one.
.TerrainLayout
    #DB 0x01, 0x01, 0x07, 0x03, 0x02, 0x01, 0x04, 0x0C, 0x0C, 0x0C
    #DB 0x02, 0x06, 0x00, 0x0D, 0x0D, 0x00, 0x05, 0x04, 0x0E, 0x0C
    #DB 0x00, 0x02, 0x0D, 0x0D, 0x0C, 0x0D, 0x01, 0x04, 0x0C, 0x0C
    #DB 0x02, 0x05, 0x0D, 0x0C, 0x0C, 0x0C, 0x0D, 0x07, 0x04, 0x0C
    #DB 0x00, 0x05, 0x04, 0x0C, 0x0C, 0x0C, 0x0C, 0x0D, 0x05, 0x04
    #DB 0x07, 0x05, 0x04, 0x0C, 0x0C, 0x0F, 0x0C, 0x0D, 0x01, 0x06
    #DB 0x03, 0x05, 0x04, 0x04, 0x0C, 0x0F, 0x0C, 0x0C, 0x0D, 0x01
    #DB 0x01, 0x07, 0x05, 0x04, 0x0A, 0x0F, 0x0B, 0x0C, 0x0D, 0x00
    #DB 0x06, 0x02, 0x00, 0x05, 0x08, 0x08, 0x08, 0x0D, 0x03, 0x07
    #DB 0x01, 0x06, 0x07, 0x00, 0x09, 0x09, 0x09, 0x00, 0x02, 0x01

.InitializeClock
    LD N, 0x03                          ; ReadClock
    LD O, 0x00                          ; Milliseconds
    LD PQR, .ClockTimeMsPrevious        ; Destination address
    INT 0x00, N                         ; Machine interrupt
    RET

; This routine calculates the delta time between cycles
; Sets the A register to 1 if the desired frame rate has been reached
.HasUpdateTimePassed
    LD N, 0x03                          ; ReadClock
    LD O, 0x00                          ; Milliseconds
    LD PQR, .ClockTimeMs                ; Set the destination address to .ClockTimeMs
    INT 0x00, N                         ; Machine interrupt
    LD FGHI, (.ClockTimeMsPrevious)     ; Load the previous clock time
    LD JKLM, (.ClockTimeMs)             ; Load the new clock time

    SUB JKLM, FGHI                      ; Calculate the delta between the current and previous clock ms
    LD OPQR, (.TargetFrameTime)         ; Get the value of the target frame rate
    CP JKLM, OPQR                       ; Compare the delta with the target frame time
    JR GT, .updateClockTick             ; If the  delta is GTE than the target, we jump
    RESF Z                              ; The frame rate has not been reached, so reset flag Z
    RET

.updateClockTick
    ; The frame rate has been reached
    LD JKLM, (.ClockTimeMs)             ; Load the new clock time again
    LD (.ClockTimeMsPrevious), JKLM     ; Store the new time as the previous for next iteration
    SETF Z                              ; Sets flag zero
    RET


; Frame rate related memory
.TargetFrameTime
    ; We prepend 3 extra bytes of zeroes, since we need to compare to an 4 byte register
    #DB 0, 0, 0, 16                     ; 16 ms between updates per frame should give approx. 60 FPS
    ;#DB 0, 0, 0x3E8                    ; 1000 ms
.ClockTimeMs
    #DB 0x00000000                      ; 32 bits for clock ms
.ClockTimeMsPrevious
    #DB 0x00000000                      ; 32 bits for clock ms
; Expects the input value as a byte in Z register
; Returns oscilated value back in Z register

; INPUT     OUTPUT
; 0         0
; 1         2
; 2         4
; ...
; 126       252
; 127       254     -> peak
; 128       252
; 129       250
; ...
; 243       4
; 254       2
; 255       0
.GetOscillation
    CP Z, 128
    JR GTE, .oscillationDecremental
    MUL Z, 2
    RET
.oscillationDecremental
    PUSH A
    SUB Z, 128
    MUL Z, 2
    LD A, Z
    LD Z, 254
    SUB Z, A
    POP A
    RET

; This holds some data and reserved space for tile sheets
; It should be clear that changing the size of the tilesheets MUST absolutely
; also reflect in changing the reserved sizes below
; Always define the size of the buffers for data you load, otherwise include
; this file LAST so it will be able to use any free memory without overwriting
; some other code included after it.
.PathTilesA
    #DB "programs\isometric-demo\img\tilesA.png", 0

.PathTilesB
    #DB "programs\isometric-demo\img\tilesB.png", 0

.PathBackground
    #DB "programs\isometric-demo\img\background.png", 0

.TilesAData
    #DB [6144] 0          ; Reserving space for the first page of tiles (128px X 48px)

.TilesBData
    #DB [6144] 0          ; Reserving space for the second page of tiles (128px X 48px)

.Layer0Palette
    #DB 0x000000
