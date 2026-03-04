//==========================
// Summercart 64 Definitions
//=========================
constant SC64_PREFIX = $BFFF
constant SC64_IDENT = $53437632

constant SC64_BUFFER_BASE = $BFFE0000
constant SC64_REGISTER_BASE = $BFFF0000

// SC64 Registers
constant SCR        = $0000 // Command execution and status
constant DATA0      = $0004 // Command argument/result 0
constant DATA1      = $0008 // Command argument/result 1
constant IDENTIFIER = $000C // Flashcart identifier
constant KEY        = $0010 // SC64 register access lock/unlock
constant IRQ        = $0014 // IRQ clear and enable
constant AUX        = $0018 // Auxiliary interrupt data channel

constant SC64_REGISTER_SCR      = SC64_REGISTER_BASE + SCR
constant SC64_REGISTER_DATA0    = SC64_REGISTER_BASE + DATA0
constant SC64_REGISTER_DATA1    = SC64_REGISTER_BASE + DATA1
constant SC64_REGISTER_ID       = SC64_REGISTER_BASE + IDENTIFIER
constant SC64_REGISTER_KEY      = SC64_REGISTER_BASE + KEY
constant SC64_REGISTER_IRQ      = SC64_REGISTER_BASE + IRQ
constant SC64_REGISTER_AUX      = SC64_REGISTER_BASE + AUX

constant SC64_REGISTER_KE

// SC64 Command
constant CMD_USB_WRITE          = $004D // Write USB data 
constant CMD_USB_READ           = $006D // Read USB data
constant CMD_IDENTIFIER_GET     = $0076 // Get identifier
constant CMD_USB_READ_STATUS    = $0075 // Read USB status
constant CMD_USB_WRITE_STATUS   = $0055 // Write USB status