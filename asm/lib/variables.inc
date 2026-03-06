// Specifics based on OOT

constant code_rom = $00A87000
constant code_ram = $800110A0

constant dmadata = $00007430
constant dmadata_index = 1510
constant hook_point = $800A1F74

// Thread Start Code
constant sc64_thread_vrom = $0347e040
//constant sc64_thread_vram = $80400000
constant sc64_thread_vram = $80500000
constant sc64_stack_context = sc64_thread_vram + $8000
constant sc64_stack_start = sc64_stack_context + $100
constant sc64_stack_end = sc64_stack_start + $500
constant os_thread_pointer = sc64_stack_end + $200