import json
import socket

from src.oot.comm import OotComm

class StreamingJsonDecoder:
    def __init__(self):
        self.decoder = json.JSONDecoder()
        self.pos = 0
        #self.data_list = []

    def decode(self, content):
        self.pos = 0
        data_list = []

        while True:
            try:
                obj, pos = self.decoder.raw_decode(content, self.pos)
                data_list.append(obj)
                self.pos = pos
            except json.JSONDecodeError:
                break
            except IndexError: # Catches when pos goes out of bounds at the end
                break

        return data_list


replacements = {
    (0x801C8464, 4): b'\x80\x40\x00\x00',
    (0x80400000, 4): b'\x80\x40\x00\x20',
    (0x80400E9F, 4): b'\x03\x48\x0D\xAA',
    (0x80400EAD, 1): b'\x01'
}

def run_command(command, comm):
    if command['func'] == 'read':
        address = int(command['addr'], 16) | 0x80000000
        size = int(command['size'])

        is_connected = bool(comm.sc64.serial)
        print(f"is_connected: {is_connected}")

        if not is_connected:
            if (address, size) in replacements:
                res = replacements[(address, size)]
            else:
                res = bytes([x for x in range(0, size)])
            
            return { "data": res.hex() }

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
            return {"err": "failed"}
        return { "data": res.hex() }
    elif command['func'] == 'write':
        address = int(command['addr'], 16) | 0x80000000
        data = bytes.fromhex(command['addr'])
        is_connected = bool(comm.sc64.serial)

        ack = False
        if is_connected:
            ack = comm.write_memory(address=address, data=data)

        return {'ack': ack}
    else:
        return {'error': 'Invalid function'}
    

def run_server():
    comm = OotComm()

    if not comm.connect():
        print("Device not available")
        #return

    # Define the host and port
    HOST = '127.0.0.1'  # Bind to localhost
    PORT = 37211        # Port to listen on (ports > 1024 are recommended)

    decoder = StreamingJsonDecoder()
    # Create a TCP/IP socket
    # socket.AF_INET specifies the IPv4 address family
    # socket.SOCK_STREAM specifies a TCP socket (stream)
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Bind the socket to the address and port
    server_socket.bind((HOST, PORT))

    # Listen for incoming connections (max 1 queued connection)
    server_socket.listen(1)
    print(f"Server listening on {HOST}:{PORT}")

    while True:
        # Accept a new connection
        # This call blocks until a client connects
        conn, client_address = server_socket.accept()
        print(f"Connected by {client_address}")

        try:
            # Receive data in a loop until the client closes the connection
            while True:
                data = conn.recv(1024) # Receive up to 1024 bytes of data
                if not data:
                    # If no data is received, the client has disconnected
                    break
                
                print(f"Received from client: {data.decode('utf-8')}")
                commands = decoder.decode(data.decode('utf-8'))
                for command in commands:
                    result = run_command(command, comm)

                    if result:
                        out = json.dumps(result) + "\n"
                        print(f"Sending to client: {out}", end='')
                        conn.sendall(out.encode('utf-8'))
                
        except ConnectionResetError:
            pass
        finally:
            # Close the connection
            conn.close()
            print(f"Connection with {client_address} closed")

if __name__ == '__main__':
    run_server()