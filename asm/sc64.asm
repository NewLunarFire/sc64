arch n64.cpu
endian msb

include "lib/n64.inc"       // Include N64 Definitions
include "lib/oot.inc"       // Include oot definitions
include "lib/sc64.inc"      // Include Summercart 64 definitions
include "lib/macros.inc"    // Macros
include "lib/variables.inc" // Variables related to hooking / dmadata


origin sc64_thread_vrom
base sc64_thread_vram

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
addiu t0,r0,5
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
sw t0, $0010(sp)

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

cmd_handle_echo:
load_to_register(t1, $4543484F) // ECHO
pi_write(t1, SC64_BUFFER_BASE + $0120)

// Echo data
addu a0,r0,s0
jal sc64_send_usb
nop

j cmd_handle_end
nop

cmd_handle_read:
load_to_register(t1, $52454144) // READ
pi_write(t1, SC64_BUFFER_BASE + $0120)

pi_read(t0, SC64_BUFFER_BASE + $0004) // Read start address in t0

// Read value from main RAM, write to buffer
lw t2, 0(t0)
pi_write(t2, SC64_BUFFER_BASE + $0004)

// Get length of data
lw a0, $0010(sp)
andi a0,a0,$01FF

// Write header + data
addiu a0,a0,4
jal sc64_send_usb
nop

j cmd_handle_end
nop

cmd_handle_write:
load_to_register(t1, $57524954) // WRIT
pi_write(t1, SC64_BUFFER_BASE + $0120)

j cmd_handle_end
nop

// addu s0,v1,r0 // Save bytes read to s0

// // Increment and save call count of recv usb to buffer
// pi_read(t0, SC64_BUFFER_BASE + 0x0028)
// addiu t0,t0,1
// pi_write(t0, SC64_BUFFER_BASE + 0x0028)

// jal sc64_recv_usb
// nop

// pi_read(t0, SC64_BUFFER_BASE)
// srl t0,t0,24
// pi_write(t0, SC64_BUFFER_BASE + $0024)


// srl t2,t0,24 // Isolate command byte
// addiu t1,r0,$0052 // 'R'
// beq t2,t1,cmd_handle_read
// nop
// addiu t1,r0,$0045 // 'E'
// beq t2,t1,cmd_handle_echo
// nop

// // addiu t1,r0,$0057 // 'W'
// // beq t0,t1,cmd_handle_write
// // nop

// j cmd_handle_end
// nop

// cmd_handle_read:
// // load_to_register(t1, $52454144)
// // sw t1, $0020(t0)
// // lw a0, $0004(t0) // Read source address
// // to_vram_address(a0)

// // addiu a1,t0,8 // Destination address = BUFFER_BASE + 8

// // // Copy from memory to receive buffer
// // lh a2, $0002(t0) // Load length

// // addu t1,r0,$0FFF
// // and a2,a2,t1 // Keep lower 12 bits for length
// // //sw a2, $0000(t0)
// // //addiu a2,r0,2
// // addiu s0,a2,8 // Copy the length + 8 for writeback
// // jal bcopy
// // nop

// // lui t0, $BFFE
// // lb t2, $0000(t0)
// // ori t2,t2,$0020
// // sb t2, $0000(t0)

// // // Write back result
// // jal sc64_send_usb
// // addu a0,r0,s0

// j cmd_handle_end
// nop

// cmd_handle_echo:
// load_to_register(t1, $4543484F) // Echo
// pi_write(t1, SC64_BUFFER_BASE + $0020)
// // srl t2,t0,16
// // and t2,t2,$00FF
// // pi_write(t2, SC64_BUFFER_BASE + $0024) // Write frame ID



// // jal sc64_send_usb
// nop

// j cmd_handle_end
// nop

// // cmd_handle_write:
// // lui t0, $BFFE

// // addiu a0,t0,8 // Source address = BUFFER_BASE + 8

// // lw a1, $0004(t0) // Read destination address
// // to_vram_address(a1)

// // lhu a2, $0002(t0) // Load length
// // andi a2,a2,$0FFF // Keep lower 12 bits for length

// // jal bcopy
// // nop

// // // Write back result
// // addiu a0,r0,CMD_USB_WRITE
// // lui a1,$BFFE
// // jal sc64_run_command
// // addiu a2,r0,8 // Write back 8 bytes (skip data)

// // // We're the last command, the jump is not useful
// // //j cmd_handle_end
// // //nop

cmd_handle_end:

// Check
mfc0 t1, Count
srl t1,t1,27
beq s4,t1,sc64_main_loop
nop

addu s4,t1,r0

lui t0,SC64_PREFIX
load_to_register(t1, 0x41424344) // ABCD
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
constant sc64_thread_vrom_size = sc64_section_end - sc64_section_start
origin dmadata + (dmadata_index * $10)
dw sc64_thread_vrom, sc64_thread_vrom_size + sc64_thread_vrom , sc64_thread_vrom, 0

// sc64 init code
origin $b78aec
base $80102B8C

sc64_init:
// Replace previous instruction
jal $80005EC0  
nop

// DMA SC64 code
load_to_register(a0, sc64_thread_vram)
load_to_register(a1, sc64_thread_vrom)
load_to_register(a2, sc64_thread_vrom_size)
jal dma_load_file
nop

// init stack
load_to_register(a0, sc64_stack_context)
load_to_register(a1, sc64_stack_start)
load_to_register(a2, sc64_stack_end)
load_to_register(t9, 0x100)
sw t9, $0010(sp)
load_to_register(t0, thread_name)
sw t0, $0014(sp)
jal os_init_stack
or a3, r0, r0

// create thread
load_to_register(a0, os_thread_pointer)
load_to_register(a1, 42)
load_to_register(a2, sc64_thread_vram)
load_to_register(t1, sc64_stack_end)
load_to_register(t2, 11)
sw t1, $0010(sp)
sw r0, $0014(sp)

jal os_create_thread
or a3, r0, r0

// start thread
load_to_register(a0, os_thread_pointer)
jal os_start_thread
nop

// Return from hook
j (hook_point+8)
nop

thread_name:
db "sc64", 0

// Hooking code
origin (hook_point - code_ram + code_rom)
base hook_point

j sc64_init
print "sc64_init: ", hex:sc64_init, "\n"
