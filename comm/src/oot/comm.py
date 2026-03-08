from .decoder import decode
from src.util import find_first
from src.sc64.comm import Sc64Comm

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

def create_command(command_id: bytes, frame_id: int, length: int, data: bytearray):
    buffer = bytearray()
    buffer += command_id.encode()                 # Command
    buffer += frame_id.to_bytes(1)                  # Frame id
    buffer += length.to_bytes(2, byteorder='big')   # Length
    buffer += data                                  # Data
    return buffer

class OotComm:
    def __init__(self, sc64=Sc64Comm()):
        self.responses = []
        
        self.sc64 = sc64
        self.sc64.on_usb_data = self.on_usb_data
        self.sc64.on_data_flushed = lambda : print("Data flushed")

        self.frame_id = 0

        self.timeout = 10
        pass

    def connect(self, file="/dev/ttyUSB0"):
        return self.sc64.connect(file=file)

    def get_and_increment_frame_id(self):
        self.frame_id = (self.frame_id % 255) + 1
        return self.frame_id

    def echo(self, data):
        pass

    def read_memory(self, address, size):
        frame_id = self.get_and_increment_frame_id()
        command = create_command('R', frame_id=frame_id, length=size, data=address.to_bytes(4, byteorder='big'))
        self.__send_command(command)
        response = self.__wait_response(frame_id)
        if response:
            return response.data

    def write_memory(self, address, data):
        frame_id = self.get_and_increment_frame_id()
        command = create_command('W', frame_id=frame_id, length=len(data), data=address.to_bytes(4, byteorder='big') + data)
        self.__send_command(command)
        response = self.__wait_response(frame_id)
        return bool(response)

    def __send_command(self, data):
        self.sc64.send_usb(data)
    
    def on_usb_data(self, data):
        response = decode(data)
        if response:
            print(response)
            self.responses.append(response)

    def __wait_response(self, frame_id):
        start = time.time()

        while time.time() - start < self.timeout:
            self.sc64.read()

            response = find_first(self.responses, lambda response: response.frame_id == frame_id)
            if response:
                self.responses.remove(response)
                return response

        return None


