# RISC-V Assembly code to find GCD of two numbers using Euclidean algorithm
#to verify this program: s0 and result will store the result
# program stops at ecall.

.data
    result: .word   0       # Variable to store the GCD, or s0
    first:  .word 36
    second: .word 48
.text
    # Load the two numbers into registers
    #li      a0, 36 #first number
    #li      a1, 48 # second number
    lw a0, first # frist number
    lw a1, second#second number 
    
    # Initialize variables
    mv      s0, a0      # s0 = num1
    mv      s1, a1      # s1 = num2

gcd_loop:
    # Check if num2 is zero
    beqz    s1, gcd_done

    # Calculate remainder using the remainder operator
    rem     s2, s0, s1

    # num1 = num2, num2 = remainder
    mv      s0, s1
    mv      s1, s2

    # Repeat the loop
    j       gcd_loop

gcd_done:
    # GCD is in s0, store it in the result variable
    sw      s0, result, t0

