from decoder import Sc64Comm
from serial import Serial
from typing import Optional
import time



def reset_comm(ser: Serial):
    ser.dtr = True

    while not ser.dsr:
        pass

    ser.dtr = False
    while ser.dsr:
        pass

def write_command(ser: Serial, command: str, arg1: int = 0, arg2: int = 0, data: Optional[bytes] = None):
    buffer = bytearray()
    buffer += b"CMD"
    buffer += command[0].encode()
    buffer += arg1.to_bytes(4, byteorder='big')
    buffer += arg2.to_bytes(4, byteorder='big')
    if data:
        buffer += data
    
    print(buffer)
    ser.write(buffer)
    ser.flush()

def oot_read_command(frame_id: int, length: int, address: int):
    buffer = bytearray()
    buffer += b'R'                                  # Command
    buffer += frame_id.to_bytes(1)                  # Frame id
    buffer += length.to_bytes(2, byteorder='big')   # Length
    buffer += address.to_bytes(4, byteorder='big')  # Address
    return buffer

def main():
    comm = Sc64Comm()
    ser = Serial("/dev/ttyUSB0", timeout=1)

    print("ttyUSB0 opened")

    reset_comm(ser)

    print("Reset done")

    #write_command(ser, 'v')

    #res = ser.read(12)

    frame_id = 1
    
    
    # Get current time in nanoseconds and convert to milliseconds
    ms = time.time_ns() // 1_000_000

    buffer = oot_read_command(frame_id=frame_id, length=2, address=0x8011A604)
    print(buffer)
    write_command(ser, 'U', 1, len(buffer), buffer)

    while True:
        res = ser.read(10)
        comm.decode(res)

        # if (time.time_ns() // 1_000_000) - ms > 3000:
        #     ms = time.time_ns() // 1_000_000
                
        #     # Read Rupee count
        #     buffer = oot_read_command(frame_id=frame_id, length=2, address=0x8011A604)
        #     print(buffer)
        #     write_command(ser, 'U', 1, len(buffer), buffer)

        #     frame_id = (frame_id + 1) % 256

if __name__ == "__main__":
    main()
