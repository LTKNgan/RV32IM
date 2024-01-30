#chuong trinh nay kiem tra tinh dung dan cua signed sw, lw, neu dung het thi lap vo tan
.data
hello: .word

.text

    addi x3, x0, 0xff
    sw x3, hello, x1
