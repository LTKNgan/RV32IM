addi x1, zero, -1
addi x2, zero, -2
slt x3, x2, x1 #1
slti x3, x2, -1 # 1
sltu x3, x2, x1# 1
sltiu x3, x2, -1#0 in this case, the program wrong
#result in x3