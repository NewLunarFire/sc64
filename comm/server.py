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