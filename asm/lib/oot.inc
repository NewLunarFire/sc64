//=========================
// Ocarina of Time Includes
//=========================

// N64 os functions
constant dma_load_file = $80000DF0
constant os_init_stack = $80001890
constant os_create_thread = $80002F20
constant os_start_thread = $80005EC0
constant __osPiGetAccess = $80001DB0
constant __osPiRelAccess = $80001DF4

// # void bcopy(const void* src, void* dest, u32 size)
// # Copy a block of memory
// # A0 = Pointer to the start of the block to copy
// # A1 = Pointer to where the block should be written
// # A2 = u32 block size
constant bcopy = $80004DC0

// void bzero(void* dest, u32 size)
// Erase a block of memory
// A0 = Pointer to the start of the block
// A1 = u32 block size
constant bzero = $80002E80

// s32 osPiRawWriteIo(u32 devAddr, u32 data)
// Perform a 32-bit IO Write operation to the PI device
// A0 = u32 device address to which the write operation should be performed
// A1 = u32 data to write
// V0 = 0 for success
constant osPiRawWriteIo = $80005910