# Protocol for communication with OOT (Proposal)

0 - Command ID (8 bits)
1 - Frame Number (Atomic counter starting from 1) (8 bits)
2 - Length (16 bits), limited to 512 bytes
4 - Address
8 - Data (if applicable)

Desired (but not required):
- Checksum
- Start - End of packet (for packets spanning multiple read/writes)
- Bunching writes together (for atomicity)
- Changing command id from uppercase to lowercase to indicate response?
- Response for invalid command?

## Commands
### (E)cho

Writes back the same data as received

## (R)ead

Reads from RDRAM.

## (W)rite

Write to RDRAM