#tinh giai thua
#test: jal, mul and sub
main:
	addi	x8, x0, 2
	addi	x16, x0, 1
	addi	x10, x0, 1
	addi	x9, x0, 5
	for:	
	beq 	x8, x9, exit
	mul 	x16, x16, x8
	add	x8, x8, x10
	jal     x2, for
	exit:		
	mul 	x16, x16, x9
	sub	x16, x16, x0
	jal     x2, main
