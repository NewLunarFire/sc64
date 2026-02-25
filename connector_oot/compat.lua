function checkBizHawkVersion()
  return true
end

bit = {
    set = function(num, pos)
    end
}

mainmemory = {
    read_u32_be = function(addr)
        print(string.format("%04X", addr))
        return 0
    end,

    read_u8 = function(addr)
        print(string.format("%04X", addr))
        return 0
    end
}

emu = {
    frameadvance = function()
    end
}