import struct
import sys

from collections import namedtuple
from os import path

DmaEntry = namedtuple('DmaEntry', ["vrom_start", "vrom_end", "rom_start", "rom_end"])

def parse_dmatable(rom):
    dmatable_start = 0x00007430
    entries = []
    offset = dmatable_start
    y = 0

    while True:
        vrom_start, vrom_end, rom_start, rom_end = struct.unpack('>4i', rom[offset:offset+16])

        if vrom_start >= vrom_end:
            break

        entries.append(DmaEntry(vrom_start, vrom_end, rom_start, rom_end))
        offset += 16
    
    return entries
    
def main(romfile):
    try:
        with open(romfile, "rb") as file:
            binary_data = file.read()
    except FileNotFoundError:
        print("Error: The file was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")


    dmatable = parse_dmatable(rom=binary_data)
    for entry in dmatable[0:10]:
        print(entry)
        pass

    print(dmatable[len(dmatable)-1])
    print(len(dmatable))
    def longest_run_of_zeroes(start, end):
        cur = start
        nops = 0
        largest_nops = 0
        start = 0

        while cur < end:
            value, = struct.unpack('>i', binary_data[cur:cur+4])
            if value == 0:
                nops += 1
            else:
                if nops > largest_nops:
                    largest_nops = nops
                    start = cur - (4*nops)
                
                nops = 0
            
            cur += 4

        return largest_nops, start

    #longest_run_of_zeroes(11038720, 12102960)
    #length, start = longest_run_of_zeroes(0, 16777216)
    length, start = longest_run_of_zeroes(0X00A87000, 0X00B8AD30)
    print(f"Largest run of nops: {length}, at: {start:08x}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Missing argument")
        exit(-1)
    
    main(romfile=path.abspath(sys.argv[1]))



