#chuong trinh nay kiem tra tinh dung dan cua signed sb, lb, neu dung het thi lap vo tan
# pass
loop:
    addi x3, x0, -10
    sb x3, 5(x0)
    lb x12, 5(x0)

    beq x12, x3, loop
