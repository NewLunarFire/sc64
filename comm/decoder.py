from enum import Enum
import struct

class CommState(Enum):
    BEGIN = 0
    READ_ID = 1
    READ_LENGTH = 2
    READ_DATA = 3

class PacketType(Enum):
    CMP = 1
    ERR = 2
    PKT = 3

class Sc64Comm:
    def __init__(self):
        self.state = CommState.BEGIN
        self.id = None
        self.ptype = None
        self.running_buffer = None
        self.callbacks = []

    def decode(self, data):
        ptr = 0
        if self.running_buffer:
            data = self.running_buffer + data

        while ptr < len(data):
            remaining = len(data) - ptr
            if self.state == CommState.BEGIN:
                if remaining < 3:
                    self.running_buffer = data[ptr:]
                    return

                rtype = data[ptr:ptr+3]

                if rtype == b'CMP':
                    self.state = CommState.READ_ID
                    self.ptype = PacketType.CMP
                    ptr += 3
                elif rtype == b'ERR':
                    self.state = CommState.READ_ID
                    self.ptype = PacketType.ERR
                    ptr += 3
                elif rtype == b'PKT':
                    self.state = CommState.READ_ID
                    self.ptype = PacketType.PKT
                    ptr += 3
                else:
                    ptr += 1
            elif self.state == CommState.READ_ID:
                self.id = data[ptr]
                self.state = CommState.READ_LENGTH
                ptr += 1
            elif self.state == CommState.READ_LENGTH:
                if remaining < 4:
                    self.running_buffer = data[ptr:]
                    return

                self.length = struct.unpack('>I', data[ptr:ptr+4])[0]
                self.state = CommState.READ_DATA
                ptr += 4
            elif self.state == CommState.READ_DATA:
                if remaining < self.length:
                    self.running_buffer = data[ptr:]
                    return

                self.data = data[ptr:ptr+self.length]
                self.state = CommState.BEGIN
                ptr += self.length

                for cb in self.callbacks:
                    cb(self.ptype, self.id, self.data)
            else:
                self.state = CommState.BEGIN
                ptr += 1

        self.running_buffer = None

    def add_callback(self, cb):
        self.callbacks.append(cb)

def main():
    comm = Sc64Comm()
    with open('data.bin', 'rb') as f:
        data = f.read()
    
    ptr = 0
    while ptr < len(data):
        comm.decode(data[ptr:ptr+10])
        ptr += 10
    
if __name__ == "__main__":
    main()

