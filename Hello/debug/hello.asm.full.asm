
#ORG 0x08000 ;gives some space for the OS

.BEGIN
    LD A, 0x01    ; Read Keyboard Buffer 
    INT 0x02, A  ; Interrupt event A as origin
    CP A, 27     ; ESC was pressed
    JP EQ, .ESC_PRESSED
    LD 32,0x00F42400
    JP .BEGIN

.ESC_PRESSED

    RET ;quit program




