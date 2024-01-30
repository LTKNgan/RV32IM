# this will test: aupic, jal, load and store
# pass if x8 = 45
		.data
data:	.word 0


.text
main:
	addi	x9, x0, 43
	sw	x9, data, x1
	lw	x8, data
	addi	x8, x8, 2
	j main 