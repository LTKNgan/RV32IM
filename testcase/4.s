#chuong trinh nay kiem tra tinh dung dan cua  lbu 
#pass het thi lap vo tan

loop:
    addi x3, x0, 0xFF
    sb x3, 5(x0)
    lbu x12, 5(x0)

    beq x12, x3, loop
