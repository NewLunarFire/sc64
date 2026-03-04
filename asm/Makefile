# Tools
AR=bass-ubuntu/bass 
CRC=wine rn64crc/rn64crc.exe
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

# Copy to PJ64 Roms
copy: rom.z64
	cp $^ ../../Roms/

# Deploy to SC64 SD card
deploy: rom.z64
	$(SC64D) upload $^
#	$(SC64D) sd upload $^