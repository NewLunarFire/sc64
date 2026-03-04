macro load_to_register(variable register, variable value) {
    if value > $FFFF {
        variable upper_half = value >> 16
        variable remainder = value & 0xFFFF

        if remainder > 0x8000 {
            upper_half = upper_half + 1
        }

        lui register, upper_half

        if remainder != 0 {
            addiu register,register, remainder
        }
    } else {
        addiu register,r0,value
    }
}

macro lock_cart() {
    jal __osPiGetAccess
    nop

    addiu   v1, r0, $FFFE
    mfc0    v0, 12
    and     v1, v0, v1
    mtc0    v1, 12
    lui     s1, $8048
    andi    v0, v0, $0001
    sw      v0, $cf90 (s1)
    lui     v0, $a460
    lw      v1, $0014 (v0)         // (pi_bsd_dom1_lat_reg)
    lui     a1, $8048
    sw      v1, $cf98 (a1)
    lw      v0, $0018 (v0)         // (pi_bsd_dom1_pwd_reg)
    lui     a0, $8048
    sw      v0, $cf94 (a0)
}

macro unlock_cart() {
    lui     a0, $8048
    lui     v1, $a460
    lw      v0, $cf98 (a0)
    sw      v0, $0014 (v1)         // (pi_bsd_dom1_lat_reg)
    lw      v0, $cf94 (a0)
    jal     __osPiRelAccess
    sw      v0, $0018 (v1)         // (pi_bsd_dom1_pwd_reg)
    lw      v0, $cf90 (s1)
    addiu   a0, r0, $fffe
    andi    v0, v0, $0001
    mfc0    v1, 12
    and     v1, v1, a0
    or      v0, v0, v1
    mtc0    v0, 12
}


macro pi_wait(variable reg1, variable reg2) {
    lui     reg2, $a460
loop{#}:
    lw      reg1, $0010 (reg2)         // (pi_status_reg)
    andi    reg1, reg1, $0003
    bnez    reg1, loop{#}
}

macro pi_read(variable reg, variable addr) {
    lui t7, addr >> 16
    pi_wait(t8, t9)
    lw reg, addr & 0xFFFF (t7)
}

macro pi_write(variable reg, variable addr) {
    lui t7, addr >> 16
    pi_wait(t8, t9)
    sw reg, addr & 0xFFFF (t7)  
}

macro pi_write_ind(variable reg, variable reg_addr) {
    pi_wait(t8, t9)
    sw reg, 0(reg_addr)  
}

macro to_vram_address(variable reg) {
    // (addr & 0x003FFFFC) | 0x80000000 
    lui t1,$0040
    addiu t1,t1,$FFFC
    and reg,reg,t1
    lui t1,$8000
    or reg,reg,t1
}