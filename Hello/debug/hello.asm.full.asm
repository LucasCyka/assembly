
#ORG 0x08000 ;gives some space for the OS

.BEGIN
    LD A, 0x01    ; Read Keyboard Buffer 
    INT 0x02, A  ; Interrupt event A as origin
    CP A, 27     ; ESC was pressed
    JP EQ, .ESC_PRESSED
    LD (0xFE05C0),0xFF ;plot a pixel at x = 0, y = 0 

    LD A, 0x05 ;Clear video page interrupt
    LD B, 0x00 ;PAGE
    lD C, 0xFF ;COLOR TO CLEAR

    INT 0x01, A 

    LD A, 0x06 ;Draw filled rectangle
    LD B, 1
    LD CD, 0xBE
    LD EF, 0x55
    LD GH, 0x64
    LD IJ, 0x64
    LD k,  0xF4

    INT 0x01, A



    JP .BEGIN

.ESC_PRESSED

    RET ;quit program




