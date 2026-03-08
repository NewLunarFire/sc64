"""
Simple WebSocket Server using the `websockets` library.
Install with: pip install websockets
Run with:     python websocket_server.py
"""

import asyncio
import json
import websockets
from websockets.server import WebSocketServerProtocol

from src.commands import run_command

async def handler(websocket: WebSocketServerProtocol):
    """Handle an individual client connection."""
    client_addr = websocket.remote_address

    try:
        # Listen for messages from this client
        async for raw in websocket:
            print(f"[<] {client_addr}: {raw}")

            res = None

            try:
                data = json.loads(raw)
                response = run_command(data)
            except json.JSONDecodeError:
                pass

            # Write result back to sender
            if response:
                response_json = json.dumps(response)
                print(f"[>] {client_addr}: {response_json}")
                await websocket.send(response_json)

    except websockets.exceptions.ConnectionClosedOK:
        pass  # normal close
    except websockets.exceptions.ConnectionClosedError as e:
        print(f"[!] Connection error from {client_addr}: {e}")
    finally:
        print(f"[-] Client disconnected: {client_addr}")


async def main():
    host = "localhost"
    port = 8765

    async with websockets.serve(handler, host, port):
        print(f"WebSocket server running on ws://{host}:{port}")
        print("Press Ctrl+C to stop.\n")
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")