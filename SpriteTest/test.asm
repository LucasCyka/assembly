#ORG 0x80000 ;reserves 512k for the OS before starting program

.LOAD 
    LD A, 0x04 ;ReadVideoPalleteAddress
    LD B, 0x01 ;Pallete 1
    INT 0x01, A
    LD (.Pall0Address), BCD

    LD A, 0x33 ;Load8bitpng
    LD BCD, .Sprite
    LD EFG, (.Pall0Address)
    LD HIJ, .Sprite1Data

    INT 0x04, A

    CP A, 0
    JP NE, .QUIT    
    
    LD A, 0x05;clear video page
    LD B, 0x00
    LD C, 0xFF
    INT 0x01, A
   
    LD A, 0x05;clear video page
    LD B, 0x01
    LD C, 0xFF
    INT 0x01, A

    LD A, 0x05;clear video page
    LD B, 0x02
    LD C, 0x00
    INT 0x01, A

    
    JP .BEGIN



.BEGIN

    LD A, 0x01 ;ReadKeyboardBuffer
    INT 0x02, A

    CP A, 27 ;if ESC has been pressed
    JP EQ, .QUIT

    LD A,0x10 ;DrawSprite
    LD BCD, .Sprite1Data
    LD E, 0x01
    LD FG, 0x08
    LD HI, 0x08
    LD JK, 0x20
    LD LM, 0x20
    INT 0x01, A

    JP .BEGIN

.QUIT
    RET

.Sprite
    #DB "programs\SpriteTest\assets\sprite2.png", 0

.Pall0Address ;pointer pallete 0 address
    #DB 0x0000000
.Sprite1Data
    #DB [1024] 0 ;32x32  