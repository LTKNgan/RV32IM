	.data
mul_result: 	.word 0       # Variable to store the GCD, or s0
mulh_result:  	.word 0
mulhu_result: 	.word 0
mulhsu_result: 	.word 0
div_result: 	.word 0
divu_result: 	.word 0
rem_result: 	.word 0
remu_result: 	.word 0
	
	.text
addi x1, zero, -2
addi x2, zero, -5

mul x3, x1, x2
sw x3, mul_result, x4

mulh x3, x1, x2
sw x3, mulh_result, x4

mulhu x3, x1, x2
sw x3, mulhu_result, x4

mulhsu x3, x1, x2
sw x3, mulhsu_result, x4

addi x1, zero, 14
div x3, x1, x2
sw x3, div_result, x4

divu x3, x2, x1
sw x3, divu_result, x4

rem x3, x1, x2
sw x3, rem_result, x4

remu x3, x2, x1
sw x3, remu_result, x4
