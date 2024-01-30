#test bne

loop:
	addi x3, x0, 0xFF
	addi x1, x0, -1
	add x12, x3, x1
	bne x12, x3, loop
