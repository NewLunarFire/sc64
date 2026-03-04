import struct
import rabbitizer

dmadata = 0x007430
dma_idx = 1510

dma_entry = dmadata + (dma_idx * 16)

with open('../asm/rom.z64', 'rb') as f:
    data = f.read()
    
start = struct.unpack('>I', data[dma_entry:dma_entry+4])[0]
end = struct.unpack('>I', data[dma_entry+4:dma_entry+8])[0]

vram = 0x80004000
for i in range(start, end, 4):
    word = struct.unpack('>I', data[i:i+4])[0]
    # Decode the instruction
    instr = rabbitizer.Instruction(word, vram=vram + i)
    print(f"{i:08x}: {instr}")