    .global is_digit,string_eq

    .equ    ZERO, 48
    .equ    COLON, 58          # because COLON is one after '9'
    .equ    NEWLINE, 0x0a

    .text

# returns 1 if a0 is an ascii digit
# a0 - byte
# tramples a0, t0, and t1
is_digit:
    slti    t0,a0,ZERO
    xori    t0,t0,1
    slti    t1,a0,COLON
    and     a0,t0,t1
    ret

# Compare two strings
# a0 - data1
# a1 - len1
# a2 - data2
# a3 - len2
# tramples t0,t1
string_eq:
    bne     a1,a3,done_false
string_eq_loop:
    beqz    a1,done_true
    lb      t0,(a0)
    lb      t1,(a2)
    bne     t0,t1,done_false
    addi    a0,a0,1
    addi    a2,a2,1
    addi    a1,a1,-1
    j       string_eq_loop
done_true:
    li      a0,1
    ret
done_false:
    li      a0,0
    ret