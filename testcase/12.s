addi x1, zero, -1
addi x2, zero, -1
addi x3, zero, -2
addi x4, zero, -2

jal x0, blt

exit: ecall

bgeu2: bgeu x1, x4, exit

bgeu1: bgeu x1, x2, bgeu2 

bltu: bltu x4, x1, bgeu1

bge2: bge x1, x4, bltu

bge1: bge x1, x2, bge2

blt: blt x4, x1, bge1

#di nguoc tu duoi len