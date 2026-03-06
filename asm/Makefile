# Tools
AR=bass-ubuntu/bass 
CRC=wine rn64crc/rn64crc.exe
PYTHON3=python3
SC64D=sc64-deployer/sc64deployer

# Files
BASE_ROM=ZOOTDEC.z64
SRCS=sc64.asm
INCS=$(wildcard lib/*)
.PHONY=copy deploy

rom.z64: $(SRCS) $(INCS)
	cp $(BASE_ROM) $@
	$(AR) $(SRCS) -m $@
	$(CRC) -u $@
lib/variables.inc: $(BASE_ROM)
	$(PYTHON3) scripts/variables.py $^ $@


# Copy to PJ64 Roms
copy: rom.z64
	cp $^ ../../Roms/

# Deploy to SC64 SD card
deploy: rom.z64
	$(SC64D) upload --save-type sram $^
#	$(SC64D) sd upload $^