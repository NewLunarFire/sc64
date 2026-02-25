arch n64.cpu
endian msb

include "lib/n64.inc" // Include N64 Definitions
include "lib/oot.inc" // Include oot definitions
include "lib/sc64.inc" // Include Summercart 64 definitions

macro load_to_register(variable register, variable value) {
    if value > $FFFF {
        variable remainder = value & 0xFFFF

        if remainder > 0x8000 {
            lui register, (value >> 16) + 1
        } else {
            lui register, (value >> 16)
        }

        addiu register,register, remainder
    } else {
        addiu register,r0,value
    }
}

constant dmadata = $00007430
constant dmadata_index = 1510
constant hook_point = $800A1F74
constant dma_load_file = $80000DF0
constant os_init_stack = $80001890
constant os_create_thread = $80002F20
constant os_start_thread = $80005EC0
constant __osPiGetAccess = $80001DB0
constant __osPiRelAccess = $80001DF4

macro lock_cart() {
    jal __osPiGetAccess
    nop

    addiu   v1, r0, $FFFE
    mfc0    v0, 12
    and     v1, v0, v1
    mtc0    v1, 12
    lui     s1, $8048
    andi    v0, v0, $0001
    sw      v0, $cf90 (s1)
    lui     v0, $a460
    lw      v1, $0014 (v0)         // (pi_bsd_dom1_lat_reg)
    lui     a1, $8048
    sw      v1, $cf98 (a1)
    lw      v0, $0018 (v0)         // (pi_bsd_dom1_pwd_reg)
    lui     a0, $8048
    sw      v0, $cf94 (a0)
}

macro unlock_cart() {
    lui     a0, $8048
    lui     v1, $a460
    lw      v0, $cf98 (a0)
    sw      v0, $0014 (v1)         // (pi_bsd_dom1_lat_reg)
    lw      v0, $cf94 (a0)
    jal     __osPiRelAccess
    sw      v0, $0018 (v1)         // (pi_bsd_dom1_pwd_reg)
    lw      v0, $cf90 (s1)
    addiu   a0, r0, $fffe
    andi    v0, v0, $0001
    mfc0    v1, 12
    and     v1, v1, a0
    or      v0, v0, v1
    mtc0    v0, 12
}


macro pi_wait(variable reg1, variable reg2) {
    lui     reg2, $a460
loop{#}:
    lw      reg1, $0010 (reg2)         // (pi_status_reg)
    andi    reg1, reg1, $0003
    bnez    reg1, loop{#}
}

// Thread Start Code
constant sc64_thread_vrom = $0347e040
constant sc64_thread_vram = $80400000
constant sc64_stack_context = $80408000
constant sc64_stack_start = $80500000
constant sc64_stack_end = $80500500
constant os_thread_pointer = $80500700

origin sc64_thread_vrom
base sc64_thread_vram

// sc64 thread code
sc64_section_start:

sc64_thread:
// Save registers
addiu sp, sp, -$20
sw ra, $0014(sp)

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

sc64_main_loop:
// Convert SC64 response to text
addiu t4,r0,32
add t5,r0,r0

loop1_start:
    dsll t5,t5,8
    addiu t4,t4,-4
    srlv t6,s2,t4
    andi t6,t6,$F
    addiu t6,t6,$9A
    bgtz t4, loop1_start
    dadd t5,t5,t6

// Store result on stack
sdl t5, $0000 (sp)
sw t5, $0004 (sp)

//add s0,r0,t5

// Link tunic color (801DAB6C)
lui t3, $801E
addiu t0,r0,4
sb t0, $AB6C(t3)

// Overwrite player name
lui t3, $8012
lw t0, $0000 (sp)
sw t0, $A5F4(t3)
lw t0, $0004(sp)
sw t0, $A5F8(t3)

//sh t0, $A640(t3) // Change equipment

// lock_cart()

// pi_wait(v0, v1)
// lui t0, SC64_PREFIX
// sw r0, AUX (t0)

// // Load rupee count
// lui t3, $8012
// lw s3, $A604(t3) // Rupee Counter

// Read USB status
addiu a0,r0,CMD_USB_READ_STATUS
addu a1,r0,r0
jal sc64_run_command
addu a2,r0,r0

beq v1,r0,+
// Receive USB data
addiu a0,r0,CMD_USB_READ
lui a1,$BFFE
jal sc64_run_command
addu a2,v1,r0

// Get the memory address to read
lw t0, $0000(a1)

// (t0 & 0x003FFFFC) | 0x80000000 
lui t1,$0040
addiu t1,t1,$FFFC
and t0,t0,t1
lui t1,$8000
or t0,t0,t1

lw t1, $0000(t0)
sw t1, $0004(a1)

// Write back to USB
addiu a0,r0,CMD_USB_WRITE
lui a1,$BFFE
jal sc64_run_command
addiu a2,r0,8
+;

// load_to_register(t1, $5F534352)

// pi_wait(t8, t9)
// sw t1, AUX (t2) // Write "_SCR"

// pi_wait(t8, t9)
// sw t0, AUX(t2) // Write SCR

// load_to_register(t1, $52535030)
// pi_wait(t8, t9)
// sw t1, AUX (t2) // Write "RSP0"

// pi_wait(t8, t9)
// sw v0, AUX(t2) // Write RSP0

// addiu t1,t1,1
// pi_wait(t8, t9)
// sw t1, AUX (t2) // Write "RSP1"

// pi_wait(t8, t9)
// sw v1, AUX(t2) // Write RSP1

// unlock_cart()

// jal $800058B0 // osYieldThread
// nop

// Wait for approx. a second
// mfc0 t0, 9 // Copy count to t0
// srl t0, 12
// wait_loop:
// mfc0 t1, 9 // Copy count to t1
// srl t1, 12
// beq t0,t1,wait_loop
// nop


j sc64_main_loop

nop


sc64_thread_exit:
lw ra, $0014(sp)
addiu sp, sp, $20
jr ra
nop

sc64_run_command:
// sc64_run_command
// a0 = command ID (lower 8 bits)
// a1 = data 0 (command)
// a2 = data 1 (command)
// t0 = Success / Error
// v0 = data 0 (result)
// v1 = data 1 (result)
lui t2, SC64_PREFIX
pi_wait(t0, t1)
sw a1, DATA0 (t2)
pi_wait(t0, t1)
sw a2, DATA1 (t2)
andi a0,a0,$00FF
pi_wait(t0, t1)
sw a0, SCR (t2)

lui $8000, t3

-;
pi_wait(t0, t1)
lw t0, SCR(t2)
and t4,t0,t3
bne t4,r0,-
nop

// Set t0 to -1 in case of error
lui $4000,t3
and t0,t0,t3
beq t0,r0,+
nop
addiu t0,r0,$FFFF
+;

pi_wait(t3, t4)
lw v0, DATA0 (t2)
pi_wait(t3, t4)
lw v1, DATA1 (t2)

jr ra
nop

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
