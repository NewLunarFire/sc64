from decoder import Sc64Comm
from serial import Serial
from typing import Optional

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




def main():
    comm = Sc64Comm()
    ser = Serial("/dev/ttyUSB0", timeout=3)

    print("ttyUSB0 opened")

    reset_comm(ser)

    print("Reset done")

    #write_command(ser, 'v')

    #res = ser.read(12)
    
    while True:
        # Read Rupee count        
        write_command(ser, 'U', 1, 4, 0x8011A604.to_bytes(4, byteorder='big'))

        res = ser.read(1000)
        comm.decode(res)

        
        


if __name__ == "__main__":
    main()
