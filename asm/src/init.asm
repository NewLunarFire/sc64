// sc64 init code
origin (code_rom+init_code_offset)
base (code_ram+init_code_offset)

sc64_init:
// Replace previous instruction
jal $80005EC0
nop

// DMA SC64 code
load_to_register(a0, sc64_file_vram)
load_to_register(a1, sc64_file_vrom)
load_to_register(a2, sc64_file_vrom_size)
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
load_to_register(a2, sc64_file_vram)
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