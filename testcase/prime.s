.data
.align 3
.global main
.text
main:
    li a0, 6 # number of primes to find
    li t0, 2 # start with 2
    li t1, 0 # counter for primes found
loop:
    call is_prime # check if current number is prime
    beqz a0, exit # exit if desired number of primes found
    addi t0, t0, 1 # increment current number
    j loop # repeat until desired number of primes found
exit:
    li a7, 10 # exit syscall
    ecall

is_prime:
    li t2, 2 # start with 2
    li t3, 0 # flag for prime
inner_loop:
    rem t4, t0, t2 # check remainder
    beqz t4, not_prime # if remainder is 0, not prime
    addi t2, t2, 1 # increment divisor
    blt t2, t0, inner_loop # repeat until divisor > number
    li t3, 1 # if loop completes, number is prime
not_prime:
    addi a0, t3, 0 # move flag to return value
    ret # return from function
