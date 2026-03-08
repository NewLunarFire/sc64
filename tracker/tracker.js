// Replace 'wss://echo.websocket.org' with your WebSocket server's URL
const socket = new WebSocket('ws://localhost:8765');

const items = {
    1: "Deku Nuts",
    2: "Bombs",
    6: "Slingshot",
    9: "Bombchus"
}
// Connection established
socket.addEventListener('open', (event) => {
    console.log('WebSocket connected:', event);
    // Send a message to the server once connected
    setInterval(updateTracker, 3000)
    //socket.send(JSON.stringify({ type: 'hello', content: 'world' }));
},);

// Listen for messages from the server
socket.addEventListener('message', (event) => {
    console.log('Message received:', event.data);
    // You might parse JSON data here
    try {
        const msg = JSON.parse(event.data);
        if(msg.func == "read")
        {
            updateMemoryContent(msg.data)
        }
        console.log('Parsed data:', msg);
    } catch (e) {
        // Not JSON, use as-is
    }
},);

// Listen for errors
socket.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
},);

// Connection closed
socket.addEventListener('close', (event) => {
    console.log('WebSocket closed:', event.code, event.reason);
    // Perform cleanup or attempt to reconnect
},);

const save_context = 0x11A5D0
const equipment_offset = 0x74

function updateMemoryContent(data)
{
    const bytes = data.match(/.{1,2}/g);
    const html = bytes.map(b => `<span>${b}</span>`).join('')

    document.querySelector("#memorycontent").innerHTML = html
}

function updateTracker()
{
    sendMessage({func: 'read', addr: (save_context + equipment_offset).toString(16), size: 56})
}

// Function to send data (optional, for encapsulation)
function sendMessage(message) {
    if (socket.readyState === WebSocket.OPEN) {
        socket.send(typeof message === 'object' ? JSON.stringify(message) : message);
    } else {
        console.error('WebSocket is not open. Message not sent.');
    }
}

