
sc64_run_command:
// sc64_run_command
// a0 = command ID (lower 8 bits)
// a1 = data 0 (command)
// a2 = data 1 (command)
// t0 = Success / Error
// v0 = data 0 (result)
// v1 = data 1 (result)
pi_write(a1, SC64_REGISTER_DATA0)
pi_write(a2, SC64_REGISTER_DATA1)
andi a0,a0,$00FF
pi_write(a0, SC64_REGISTER_SCR)

lui t3, $8000
addu t1,r0,r0

-;
pi_read(t0, SC64_REGISTER_SCR)

and t4,t0,t3
bne t4,r0,-
nop

// Set t0 to -1 in case of error
lui t3, $4000
and t0,t0,t3
beq t0,r0,+
nop

// Set t0 to -1
addiu t0,r0,$FFFF
+;

pi_read(v0, SC64_REGISTER_DATA0)
pi_read(v1, SC64_REGISTER_DATA1)

jr ra
nop