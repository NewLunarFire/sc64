arch n64.cpu
endian msb

include "lib/n64.inc"       // Include N64 Definitions
include "lib/oot.inc"       // Include oot definitions
include "lib/sc64.inc"      // Include Summercart 64 definitions
include "lib/macros.inc"    // Macros
include "lib/variables.inc" // Variables related to hooking / dmadata

origin sc64_file_vrom
base sc64_file_vram

// sc64 thread code
sc64_section_start:

sc64_thread:
// Save registers
addiu sp, sp, -$20
sw ra, $001C(sp)

sc64_probe:
lock_cart()

lui t0,$BFFF
pi_wait(v0, v1)
sw r0, KEY (t0)
load_to_register(t1, $5F554E4C) // _UNL
pi_wait(v0, v1) 
sw t1, KEY (t0)
load_to_register(t1, $4F434B5F) // OCK_
pi_wait(v0, v1)
sw t1, KEY (t0)

// Read identifier and compare with expected value (SCv2)
pi_wait(v0, v1)
lw s2, IDENTIFIER (t0) // Read identifier

unlock_cart()

load_to_register(t2, SC64_IDENT)
bne s2,t2,sc64_probe
nop

// Clear the receive buffer
load_to_register(t0, SC64_BUFFER_BASE)
addu t1,r0,r0

memclr_start:
addu t2,t0,t1
pi_write_ind(r0, t2)
addiu t1,t1,4
subiu t3,t1,$0100
bne t3,r0,memclr_start
nop

// Write BOOT to buffer
load_to_register(t1, $424F4F54) // BOOT
pi_write(t1, SC64_BUFFER_BASE + $0120)

mfc0 s4, Count
srl s4,s4,27

sc64_main_loop:
// Link tunic color (801DAB6C)
lui t3, $801E
addiu t0,r0,$70
sb t0, $AB6C(t3)

// Read USB status
addiu a0,r0,CMD_USB_READ_STATUS
addu a1,r0,r0
jal sc64_run_command
addu a2,r0,r0

bne t0,r0,cmd_handle_end
nop
addiu t1,r0,1
bne v0,t1,cmd_handle_end
nop
beq v1,r0,cmd_handle_end
nop

addu s0,r0,v1 // Save bytes read to s0

addu a0,r0,s0
jal sc64_recv_usb
nop

pi_read(t0, SC64_BUFFER_BASE)
sw t0, $0010(sp) // header_word

srl t3,t0,24 // Command byte
srl t4,t0,16
and t4,t4,$00FF // Frame id

pi_write(t3, SC64_BUFFER_BASE + $0124)
pi_write(t4, SC64_BUFFER_BASE + $0128)

load_to_register(t2, $0045) // E
beq t3,t2,cmd_handle_echo
load_to_register(t2, $0052) // R
beq t3,t2,cmd_handle_read
load_to_register(t2, $0057) // W
beq t3,t2,cmd_handle_write
nop

// More commands to add: (L)ock, (U)nlock, (I)dentify

j cmd_handle_end
nop

////////////////////////////////////////////////////////////
//                      ECHO Command                      //
////////////////////////////////////////////////////////////
cmd_handle_echo:
load_to_register(t1, $4543484F) // ECHO
pi_write(t1, SC64_BUFFER_BASE + $0120)

// Echo data
addu a0,r0,s0
jal sc64_send_usb
nop

j cmd_handle_end
nop

////////////////////////////////////////////////////////////
//                      READ Command                      //
////////////////////////////////////////////////////////////
cmd_handle_read:
load_to_register(t1, $52454144) // READ
pi_write(t1, SC64_BUFFER_BASE + $0120)

pi_read(t0, SC64_BUFFER_BASE + $0004) // Read address start address in t0
load_to_register(t1, SC64_BUFFER_BASE + $0004) // Buffer address start in t1

lw t2, $0010(sp) // header_word
andi t2,t2,$01FF // Length in t2

read_loop:
lw t3, 0(t0) // Read value from main RAM, write to buffer
pi_write_ind(t3, t1) // Write to SC64 buffer

addiu t0,t0,4 // Increment source address by 4
addiu t1,t1,4 // Increment destination address by 4
subiu t2,t2,4 // substract 4 from length
bgtz t2, read_loop
nop

// Get length of data
lw a0, $0010(sp)
andi a0,a0,$01FF

// Write header + data
addiu a0,a0,4
jal sc64_send_usb
nop

j cmd_handle_end
nop

////////////////////////////////////////////////////////////
//                     WRITE Command                      //
////////////////////////////////////////////////////////////
cmd_handle_write:
load_to_register(t1, $57524954) // WRIT
pi_write(t1, SC64_BUFFER_BASE + $0120)

pi_read(t0, SC64_BUFFER_BASE + $0004) // Write address start address in t0
load_to_register(t1, SC64_BUFFER_BASE + $0008) // Data buffer start in t1

lw t2, $0010(sp) // header_word
andi t2,t2,$01FF // Length in t2

write_loop:
// The write loops works on a per-byte basis
// No worries to be had with alignment, but large reads could take much longer
pi_wait(t8, t9)
lb t3, 0(t1) // Read value from buffer, 
sb t3, 0(t0) // Write to main RAM

addiu t0,t0,1 // Increment source address by 1
addiu t1,t1,1 // Increment destination address by 1
subiu t2,t2,1 // substract 1 from length
bgtz t2, write_loop
nop

// Reply with header + address
addiu a0,r0,8
jal sc64_send_usb
nop

j cmd_handle_end
nop

cmd_handle_end:

// Check
mfc0 t1, Count
srl t1,t1,27
beq s4,t1,sc64_main_loop
nop

addu s4,t1,r0

lui t0,SC64_PREFIX
pi_wait(t2,t3)
sw s4, AUX (t0)

j sc64_main_loop
nop

sc64_thread_exit:
lw ra, $001C(sp)
addiu sp, sp, $20
jr ra
nop

sc64_recv_usb:
// Receive USB data
// a0 = size

// Save registers
addiu sp, sp, -$20
sw ra, $001C(sp)

// USB sc64_run_command(CMD_USB_READ, $BFEE0000, size)
addu a2,r0,a0
load_to_register(a0, CMD_USB_READ)
load_to_register(a1, SC64_BUFFER_BASE)
jal sc64_run_command
nop

-;
// do {
// status = sc64_run_command(CMD_USB_READ_STATUS, 0, 0)
addiu a0,r0,CMD_USB_READ_STATUS
addu a1,r0,r0
addu a2,r0,r0
jal sc64_run_command
nop

lui t0,$8000
and v0,v0,t0
bne v0,r0,-
nop
// } while((status & 0x80000000) != 0)

// Restore registers
lw ra, $001C(sp)
addiu sp, sp, $20
jr ra
nop

sc64_send_usb:
// Send USB data
// a0 = size

// Save registers
addiu sp, sp, -$20
sw ra, $001C(sp)

// sc64_run_command(CMD_USB_WRITE, $BFEE0000, size)
addu a2,r0,a0
load_to_register(a0, CMD_USB_WRITE)
load_to_register(a1, SC64_BUFFER_BASE)
jal sc64_run_command
nop

-;
// do {
// status = sc64_run_command(CMD_USB_WRITE_STATUS, 0, 0)
addiu a0,r0,CMD_USB_WRITE_STATUS
addu a1,r0,r0
jal sc64_run_command
addu a2,r0,r0

lui t0,$8000
and v0,v0,t0
bne v0,r0,-
nop
// } while((status & 0x80000000) != 0)

// Restore registers
lw ra, $001C(sp)
addiu sp, sp, $20
jr ra
nop

include "src/sc64.asm"

sc64_section_end:

// Calculate size of code section for dma table
constant sc64_file_vrom_size = sc64_section_end - sc64_section_start
origin dmadata_vrom + (dmadata_index * $10)
dw sc64_file_vrom, sc64_file_vrom_size + sc64_file_vrom , sc64_file_vrom, 0

include "src/init.asm"
include "src/hook.asm"
