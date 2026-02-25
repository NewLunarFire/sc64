//==========================
// Summercart 64 Definitions
//=========================
constant SC64_PREFIX = $BFFF
constant SC64_IDENT = $53437632

// SC64 Registers
constant SCR        = $0000 // Command execution and status
constant DATA0      = $0004 // Command argument/result 0
constant DATA1      = $0008 // Command argument/result 1
constant IDENTIFIER = $000C // Flashcart identifier
constant KEY        = $0010 // SC64 register access lock/unlock
constant IRQ        = $0014 // IRQ clear and enable
constant AUX        = $0018 // Auxiliary interrupt data channel

// SC64 Command
constant CMD_USB_WRITE          = $004D // Write USB data 
constant CMD_USB_READ           = $006D // Read USB data
constant CMD_IDENTIFIER_GET     = $0076 // Get identifier
constant CMD_USB_READ_STATUS    = $0075 // Read USB status