local bitop = require("bit")
local socket = require("socket") -- require the LuaSocket library
local json = require('json')

function checkBizHawkVersion()
  return true
end


local host = "127.0.0.1" -- the remote server's IP address
local port = 37211       -- the remote server's port number

-- Create a new TCP socket object
local tcp = assert(socket.tcp())

-- Optional: set a timeout in seconds to prevent the script from blocking indefinitely
tcp:settimeout(3)

-- Connect to the remote host
local success, err = tcp:connect(host, port)

if success then
    print("Connected successfully!")
else
    print("Connection failed: " .. err)
end

local function print_table(t)
    for k, v in pairs(t) do
        print(k, v)
    end
end

local read_memory = function(addr, size)
    local command = {
        func = "read",
        addr = string.format("%08X", addr),
        size = size
    }

    print_table(command)
    local jsonCmd = json.encode(command)
    tcp:send(jsonCmd)

    local d, e = tcp:receive("*l")
    local jsonRes = json.decode(d)
    return jsonRes['data']
end

local write_memory = function(addr, data)
    local command = {
        func = "write",
        addr = string.format("%08X", addr),
        data = data
    }

    print_table(command)
    local jsonCmd = json.encode(command)
    tcp:send(jsonCmd)

    local d, e = tcp:receive("*l")
    local jsonRes = json.decode(d)
    return jsonRes['data']
end


local function hex_string_to_table(hex_string)
    local result = {}
    local index = 0

    for hex in hex_string:gmatch("%x%x") do
        result[index] = tonumber(hex, 16)
        index = index + 1
    end

    return result
end

bit = {
    band = bitop.band,
    bor = bitop.bor,

    clear = function(num, pos)
        return bitop.band(num, bitop.bnot(bitop.lshift(1, pos)))
    end,

    check = function(num, pos)
        return bitop.band(num, bitop.lshift(1, pos)) ~= 0
    end,

    lshift = bitop.lshift,
    rshift = bitop.rshift,

    set = function(num, pos)
        return bitop.bor(bitop.rshift(1, pos))
    end,
}

mainmemory = {
    readbyte = function(addr)
        print("readbyte: " .. string.format("%04X", addr))
        local val = tonumber(read_memory(addr, 1), 16)
        print("readbyte: " .. string.format("%04X", addr) .. ", res = " .. string.format("%01X", val))
        return val
    end,

    read_u8 = function(addr)
        local val = tonumber(read_memory(addr, 1), 16)
        print("read_u8: " .. string.format("%04X", addr) .. ", res = " .. string.format("%01X", val))
        return val
    end,

    read_u16_be = function(addr)
        local val = tonumber(read_memory(addr, 2), 16)
        print("read_u16_be: " .. string.format("%04X", addr) .. ", res = " .. string.format("%08X", val))
        return val
    end,

    read_u24_be = function(addr)
        local val = tonumber(read_memory(addr, 3), 16)
        print("read_u24_be: " .. string.format("%04X", addr) .. ", res = " .. string.format("%08X", val))
        return val
    end,

    read_u32_be = function(addr)
        local val = tonumber(read_memory(addr, 4), 16)
        print("read_u32_be: " .. string.format("%04X", addr) .. ", res = " .. string.format("%08X", val))
        return val
    end,

    readbyterange = function(addr, size)
        local val = read_memory(addr, size)
        tbl = hex_string_to_table(val)

        print("readbyterange: " .. string.format("%04X", addr) .. ", res = " .. val)
        return tbl
    end,

    writebyte = function(addr, val)
        write_memory(addr, string.format("%02X", val))
    end,
    write_u8 = function(addr, val)
        write_memory(addr, string.format("%02X", val))
    end,
    write_u16_be = function(addr, val)
        write_memory(addr, string.format("%04X", val))
    end,
    write_u24_be = function(addr, val)
        write_memory(addr, string.format("%06X", val))
    end,
    write_u32_be = function(addr, val)
        write_memory(addr, string.format("%08X", val))
    end
}

emu = {
    frameadvance = function()
    end
}