#chuong trinh nay kiem tra tinh dung dan cua sw, lw va beq, neu dung het thi lap vo tan
    addi x3, x0, 10
    sw x3, 5(x0)
    lw x12, 5(x0)

loop:
    addi x1, x0, 1
    addi x2, x1, 1
    addi x3, x2, 1
    addi x4, x3, 1
    addi x5, x4, 1
    add x6, x5, x5

    beq x12, x6, loop
