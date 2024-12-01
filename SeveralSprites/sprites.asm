#ORG 0x80000 ;(512KB is reserved for the OS)

.Begin
    CALL .GetPalleteAddresses
    CALL .LoadPalette
    CALL .LoadSprites
    CALL .ClearPages
    JP .Loop

.Loop
    CALL .CheckBtn
    CP A, 27 ;Check if user presed ESC
    JP EQ, .Exit


    CALL .DrawSprites


    ;continue on loop
    JP .Loop



.CheckBtn
    LD A, 0x01 ;ReadKeyboardBuffer
    INT 0x02, A ;Triggers isr input

    RET

.LoadSprites
    PUSH A,Z 

    LD A, 0x33;Load8BitPng
    LD BCD, .Sprite1File
    LD EFG, (.Pallete0Address)
    LD HIJ, .Sprite1Data

    INT 0x04, A


    LD A, 0x33;Load8BitPng
    LD BCD, .Sprite2File
    LD EFG, (.Pallete0Address)
    LD HIJ, .Sprite2Data

    INT 0x04, A


    LD A, 0x33;Load8BitPng
    LD BCD, .Sprite3File
    LD EFG, (.Pallete0Address)
    LD HIJ, .Sprite3Data

    INT 0x04, A

    POP A,Z


    RET

.DrawSprites
    PUSH A,Z

    LD A, 0x10;DrawSprie
    LD BCD, .Sprite1Data
    LD E, 0x00   ;page
    LD FG, 0x00  ;x pos
    LD HI, 0x00  ;y pos
    LD JK, 0x20  ;32 width
    LD LM, 0x20  ;32 height

    INT 0x01, A

    LD A, 0x10;DrawSprie
    LD BCD, .Sprite2Data
    LD E, 0x01   ;page
    LD FG, 0x15 ;x pos
    LD HI, 0x00  ;y pos
    LD JK, 0x20  ;32 width
    LD LM, 0x20  ;32 height

    INT 0x01, A


    LD A, 0x10;DrawSprie
    LD BCD, .Sprite3Data
    LD E, 0x02   ;page
    LD FG, 0x2A ;x pos
    LD HI, 0x00  ;y pos
    LD JK, 0x20  ;32 width
    LD LM, 0x20  ;32 height

    INT 0x01, A



    POP A,Z

    RET


.ClearPages
    PUSH A,Z

    ;Clear Page0
    LD A, 0x05;ClearVideoPage
    LD B, 0x00 
    LD C, 0x00

    INT 0x01, A

    ;Clear Page1
    LD A, 0x05;ClearVideoPage
    LD B, 0x01
    LD C, 0x00

    INT 0x01, A


    ;Clear Page2
    LD A, 0x05;ClearVideoPage
    LD B, 0x02
    LD C, 0x00

    INT 0x01, A


    POP A,Z

    RET


.LoadPalette
    PUSH A, Z

    ;Pallete0
    LD A, 0x33 ;Load8BitPng
    LD BCD, .PalleteFile
    LD EFG, (.Pallete0Address)
    LD HIJ, .PalleteData

    INT 0x04, A  


    ;Pallete1
    LD A, 0x33 ;Load8BitPng
    LD BCD, .PalleteFile
    LD EFG, (.Pallete1Address)
    LD HIJ, .PalleteData

    INT 0x04, A  


    ;Pallete2
    LD A, 0x33 ;Load8BitPng
    LD BCD, .PalleteFile
    LD EFG, (.Pallete2Address)
    LD HIJ, .PalleteData

    INT 0x04, A  
 

    POP A, Z

    RET

.GetPalleteAddresses
    PUSH A, Z

    LD A, 0x04;ReadVideoPaletteAddress
    LD B, 0x00;Page 0

    INT 0x01, A;
    LD  (.Pallete0Address), BCD

    LD A, 0x04;ReadVideoPaletteAddress
    LD B, 0x01;Page 1

    INT 0x01, A;
    LD  (.Pallete1Address), BCD

    LD A, 0x04;ReadVideoPaletteAddress
    LD B, 0x02;Page 2

    INT 0x01, A;
    LD  (.Pallete2Address), BCD


    POP A, Z

    RET




.Exit
    RET 

.PalleteFile
    #DB "programs\SeveralSprites\assets\pallete.png",0

.Sprite1File
    #DB "programs\SeveralSprites\assets\ball1.png",0

.Sprite2File
    #DB "programs\SeveralSprites\assets\ball2.png",0

.Sprite3File
    #DB "programs\SeveralSprites\assets\ball3.png",0


.PalleteData 
    #DB [2048] 0 ; 128x16

.Sprite1Data
    #DB [1024] 0 ;32x32

.Sprite2Data
    #DB [1024] 0 ;32x32

.Sprite3Data
    #DB [1024] 0 ;32x32

.Pallete0Address
    #DB [3] 0 ;address is 24 bits???

.Pallete1Address
    #DB [3] 0

.Pallete2Address
    #DB [3] 0