from dataclasses import dataclass
from enum import Enum
import struct

class CommandType(Enum):
    READ = 'R'
    WRITE = 'W'
    ECHO = 'E'

@dataclass
class OotPacket:
    command_type: CommandType
    frame_id: int
    length: int
    data: bytes

def decode(data):
    data = data[4:]
    command_byte = chr(data[0])
    command_type = None

    if command_byte == 'R':
        command_type = CommandType.READ
    if command_byte == 'W':
        command_type = CommandType.WRITE
    if command_byte == 'E':
        command_type = CommandType.ECHO

    frame_id = int(data[1])
    length, = struct.unpack(">h", data[2:4])
    d = data[4:]

    return OotPacket(command_type, frame_id, length, d)
