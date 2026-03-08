from .decoder import Sc64Decoder, PacketType
from src.util import find_first
from serial import Serial
from serial.tools.list_ports import comports
from serial.serialutil import SerialException
from typing import Optional

import struct
import time

def find_sc64():
    return [port.device for port in comports() if port.serial_number and port.serial_number.startswith("SC64")]

class Sc64Comm:
    def __init__(self):
        self.decoder = Sc64Decoder()
        self.serial = None
        self.debug = False
        self.timeout = 10
        self.on_aux_data = None
        self.on_usb_data = None
        self.on_data_flushed = None
        pass

    def connect(self, file=None):
        if self.serial:
            return True
        
        if not file:
            # Try to connect to any found SC64
            for port in find_sc64():
                if self.connect(port):
                    return True
            
            return False
        
        try:
            self.serial = Serial(file, timeout=0)
            print(f"Summercart64 connected on {file}")
        except SerialException as se:
            print(se)
            return False

        self.__reset_comm()
        return True
    
    def is_connected(self):
        return bool(self.serial)

    def get_identifier(self):
        self.__write_command('v')
        packet = self.__wait_response('v')

        return packet.data.decode('utf-8')

    def get_version(self):
        self.__write_command('V')
        packet = self.__wait_response('V')

        if packet:
            major, minor,revision = struct.unpack(">hhl", packet.data)
            return f"{major}.{minor}.{revision}"

        return None
    
    def read_memory(self, address, size):
        if not self.serial:
            raise "Not connected to SC64"
        
        self.__write_command('m', address, size)
        packet = self.__wait_response('m')

        return packet.data if packet else None

    def write_memory(self, address, data):
        if not self.serial:
            raise "Not connected to SC64"
        
        self.__write_command('M', address, len(data), data)
        packet = self.__wait_response('M')

        return packet.data if packet else None

    def send_usb(self, data):
        self.__write_command('U', 1, len(data), data)

    def __wait_response(self, command_id):
        start = time.time()

        while time.time() - start < self.timeout:
            packets = self.read()
            packet = find_first(packets, lambda packet: packet.type == PacketType.CMP and packet.command_id == command_id)
            if packet:
                return packet

        return None
        
    def read(self):
        res = self.serial.read(self.serial.in_waiting)
        if res:
            if self.debug:
                print(f"sc64 recv: {res}")
            
            packets = self.decoder.decode(res)

            for packet in packets[:]:
                if packet.type == PacketType.PKT:
                    if packet.command_id == 'X' and self.on_aux_data:
                        self.on_aux_data(packet.data)
                    elif packet.command_id == 'U' and self.on_usb_data:
                        self.on_usb_data(packet.data)
                    elif packet.command_id == 'G' and self.on_data_flushed:
                        self.on_data_flushed()

                    packets.remove(packet)

            return packets
        
        return []

    def __reset_comm(self):
        self.serial.dtr = True

        while not self.serial.dsr:
            pass

        self.serial.dtr = False
        while self.serial.dsr:
            pass

    def __write_command(self, command: str, arg1: int = 0, arg2: int = 0, data: Optional[bytes] = None):
        if not self.serial:
            raise "Not connected to SC64"
        
        buffer = bytearray()
        buffer += b"CMD"
        buffer += command[0].encode()
        buffer += arg1.to_bytes(4, byteorder='big')
        buffer += arg2.to_bytes(4, byteorder='big')
        if data:
            buffer += data
        
        if self.debug:
            print(f"sc64 send: {buffer}")
        
        self.serial.write(buffer)
        self.serial.flush()


