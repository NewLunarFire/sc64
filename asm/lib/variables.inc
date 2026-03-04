// Specifics based on OOT

constant code_rom = $00A87000
constant code_ram = $800110A0

constant dmadata = $00007430
constant dmadata_index = 1510
constant hook_point = $800A1F74

// Thread Start Code
constant sc64_thread_vrom = $0347e040
constant sc64_thread_vram = $80400000
constant sc64_stack_context = $80408000
constant sc64_stack_start = $80500000
constant sc64_stack_end = $80500500
constant os_thread_pointer = $80500700