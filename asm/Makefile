# Tools
AR=bass-ubuntu/bass 
CRC=tools/n64crc
DECOMPRESS=tools/decompressor
PYTHON3=python3
SC64D=sc64-deployer/sc64deployer

# Files
BUILD_DIR := build
Z64_FILES := $(wildcard *.z64)
DECOMP_FILES := $(patsubst %.z64,$(BUILD_DIR)/%-decomp.z64,$(Z64_FILES))
SC64_FILES := $(patsubst %.z64,$(BUILD_DIR)/%-sc64.z64,$(Z64_FILES))

SRCS=sc64.asm
INCS=$(wildcard lib/*)

.PHONY=clean

all: $(SC64_FILES)

$(BUILD_DIR)/%-sc64.z64: $(BUILD_DIR)/%-decomp.z64 | $(BUILD_DIR)
	cp $< $@
	$(AR) $(SRCS) -m $@
	$(CRC) $@

$(BUILD_DIR)/%-decomp.z64: %.z64 | $(BUILD_DIR)
	$(DECOMPRESS) --ignore-filesize $< $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

lib/variables.inc: $(BASE_ROM)
	$(PYTHON3) scripts/variables.py $^ $@

clean:
	rm -rf $(BUILD_DIR)
