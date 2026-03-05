from dataclasses import dataclass
from enum import Enum
import struct

class DecoderState(Enum):
    BEGIN = 0
    READ_ID = 1
    READ_LENGTH = 2
    READ_DATA = 3

class PacketType(Enum):
    CMP = 1
    ERR = 2
    PKT = 3

@dataclass
class Sc64Packet:
    type: PacketType
    command_id: int
    data: bytes

class Sc64Decoder:
    def __init__(self):
        self.state = DecoderState.BEGIN
        self.id = None
        self.ptype = None
        self.running_buffer = None

    def decode(self, data):
        decoded_packets = []
        ptr = 0
        
        if self.running_buffer:
            data = self.running_buffer + data

        while ptr < len(data):
            remaining = len(data) - ptr
            if self.state == DecoderState.BEGIN:
                if remaining < 3:
                    break

                rtype = data[ptr:ptr+3]

                if rtype == b'CMP':
                    self.state = DecoderState.READ_ID
                    self.ptype = PacketType.CMP
                    ptr += 3
                elif rtype == b'ERR':
                    self.state = DecoderState.READ_ID
                    self.ptype = PacketType.ERR
                    ptr += 3
                elif rtype == b'PKT':
                    self.state = DecoderState.READ_ID
                    self.ptype = PacketType.PKT
                    ptr += 3
                else:
                    ptr += 1
            elif self.state == DecoderState.READ_ID:
                self.id = chr(data[ptr])
                self.state = DecoderState.READ_LENGTH
                ptr += 1
            elif self.state == DecoderState.READ_LENGTH:
                if remaining < 4:
                    break

                self.length = struct.unpack('>I', data[ptr:ptr+4])[0]
                ptr += 4

                if self.length == 0:
                    packet = Sc64Packet(self.ptype, self.id, b'')
                    decoded_packets.append(packet)
                    self.state = DecoderState.BEGIN
                else:
                    self.state = DecoderState.READ_DATA
                
            elif self.state == DecoderState.READ_DATA:
                if remaining < self.length:
                    break

                self.data = data[ptr:ptr+self.length]
                self.state = DecoderState.BEGIN
                ptr += self.length

                packet = Sc64Packet(self.ptype, self.id, self.data)
                decoded_packets.append(packet)
            else:
                self.state = DecoderState.BEGIN
                ptr += 1

        self.running_buffer = data[ptr:]
        return decoded_packets


def main():
    comm = Sc64Decoder()
    with open('data.bin', 'rb') as f:
        data = f.read()
    
    ptr = 0
    while ptr < len(data):
        packets = comm.decode(data[ptr:ptr+10])
        for packet in packets:
            print(packet)
        ptr += 10
    
if __name__ == "__main__":
    main()

