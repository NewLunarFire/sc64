from select import select
from sys import stdin
from serial import Serial
from decoder import Sc64Comm, PacketType
from serial import Serial
from typing import Optional


import atexit
import builtins
import signal   
import sys
import tty
import termios
import time

def oot_read_command(frame_id: int, length: int, address: int):
    buffer = bytearray()
    buffer += b'R'                                  # Command
    buffer += frame_id.to_bytes(1)                  # Frame id
    buffer += length.to_bytes(2, byteorder='big')   # Length
    buffer += address.to_bytes(4, byteorder='big')  # Address
    return buffer

def oot_echo_command(frame_id: int, data: bytearray):
    buffer = bytearray()
    buffer += b'E'                                      # Command
    buffer += frame_id.to_bytes(1)                      # Frame id
    buffer += len(data).to_bytes(2, byteorder='big')    # Length
    buffer += data                                      # Data
    return buffer

frame_id = 1
def on_character(ser, char):
    global frame_id
    print(f"Got character: {repr(char)}")
    
    if char == '3': # Read
        buffer = oot_read_command(frame_id=frame_id, length=2, address=0x8011A604)
        write_command(ser, 'U', 1, len(buffer), buffer)
        frame_id += 1

    if char == '4': # Echo
        buffer = oot_echo_command(frame_id=frame_id, data=b'OOTR')
        write_command(ser, 'U', 1, len(buffer), buffer)
        frame_id += 1

    if char == '5': # Blank out receive buffer
        write_command(ser, 'M', 0x05000000, 256, b'\x00' * 256)
        
    return char != 'q' and char != '\x03'

def restore_terminal(fd, old_settings):
    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def handle_sigterm(signum, frame):
    sys.exit(0)

_real_print = print  # save a reference to the built-in first

def safe_print(*args, **kwargs):
    kwargs.setdefault("end", "\r\n")
    _real_print(*args, **kwargs)

def print_packet(ptype, id, data):
    if ptype == PacketType.PKT and id == 88:
        with open('aux.bin', 'wb') as f:
            f.write(data)
        
        #print("AUX")
        return

    elif ptype == PacketType.CMP and id == 109:
        with open('buffer.bin', 'wb') as f:
            f.write(data)

    else:
        print(f"{ptype.name} {chr(id)} ({len(data)} bytes) {data}")

def main():
    comm = Sc64Comm()
    comm.connect("/dev/ttyUSB0")
    comm.add_callback(print_packet)

    # Open serial port
    serial = Serial("/dev/ttyUSB0", timeout=0)
    print("ttyUSB0 opened")
    reset_comm(serial)
    print("Reset done")

    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    tty.setraw(fd)

    atexit.register(lambda: restore_terminal(fd, old_settings))
    builtins.print = safe_print # Replace with our own print functions that fixes the \r\n issue
    signal.signal(signal.SIGTERM, handle_sigterm)

    print("Press any key (q to quit):")
    ns = time.time_ns()

    while True:
        read_ready, _, _ = select([serial, sys.stdin], [], [], 1)
        
        if sys.stdin in read_ready:
            char = sys.stdin.read(1)
            if not on_character(serial, char):
                break
        
        if serial in read_ready:
            res = serial.read(serial.in_waiting)
            #print(res)
            comm.decode(res)

        if time.time_ns() - ns > 1_000_000_000: # 1 second
            ns = time.time_ns()
            write_command(serial, 'm', 0x05000000, 256)



if __name__ == "__main__":
    main()
