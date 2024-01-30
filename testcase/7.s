#test jalr
	addi x12, x0, -1
	jal x2, loop		
loop:
	addi x12, x12, -1 #x2
	jalr x1, x2, 0