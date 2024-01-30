li x6, 0xF0FF00F0
andi x6, x6, -1
ori x6, x6, -1
xori x6, x6, -1
li x6, 0xF0FF00F0
li x5, 0xFFFFFFFF
and x6, x6, x5
or x6, x6, x5
xor x6, x6, x6
#test all logical
# result in x6