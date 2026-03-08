from src.sc64 import get_sc64
from src.oot import get_comm

sc64 = get_sc64()
comm = get_comm(sc64)
sc64.connect()

replacements = {
    (0x801C8464, 4): b'\x80\x40\x00\x00',
    (0x80400000, 4): b'\x80\x40\x00\x20',
    (0x80400E9F, 4): b'\x03\x48\x0D\xAA',
    (0x80400EAD, 1): b'\x01',
    (0x8011a644, 56): bytes.fromhex("ff0102ffffff06ff09ffffffffffffffffffffffffffffff000a0c0000001400060000000000000011000000001040082080000000000000")
}

def read_memory(command):
    address = int(command['addr'], 16) | 0x80000000
    size = int(command['size'])

    is_connected = bool(sc64.serial)
    #print(f"is_connected: {is_connected}")

    if not is_connected:
        if (address, size) in replacements:
            res = replacements[(address, size)]
        else:
            res = bytes([x for x in range(0, size)])
        
        return command | { "data": res.hex() }

    offset = address & 0x03

    res = None
    if offset != 0:
        print(f"Unaligned memory access! offset = {offset}")

        address = address & 0xFFFFFFFC
        res = comm.read_memory(address=address, size=size+4)
        res = res[offset:offset+size]
    else:
        res = comm.read_memory(address=address, size=size)
    
    print(res)
    if not res:
        return command | {"err": "failed"}
    
    return command | { "data": res.hex() }

def write_memory(command):
    address = int(command['addr'], 16) | 0x80000000
    data = bytes.fromhex(command['addr'])
    is_connected = bool(sc64.serial)

    ack = False
    if is_connected:
        ack = comm.write_memory(address=address, data=data)

    return command | {'ack': ack}

command_handlers = {
    "read": read_memory,
    "write": write_memory
}

def run_command(command):
    func = command['func']
    if not func:
        return {'error': 'missing function'}
    
    handler = command_handlers[func]
    if not handler:
        return {'error': 'Invalid function'}

    return handler(command)
        
    
