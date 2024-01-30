.data
	result: .word 0
.text
	main:
	    li a0, 40 # number of terms to generate
	    li t0, 0 # first term
	    li t1, 1 # second term
	    li t2, 2 # counter
	loop:
	    add t3, t0, t1 # add previous two terms
	    mv t0, t1 # shift terms
	    mv t1, t3
	    addi t2, t2, 1 # increment counter
	    blt t2, a0, loop # repeat until desired number of terms
	    
	    sw t3, result, t4
		
		