    .global is_digit,string_eq,parse_int_range,parse_int

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

# Parses a string to an integer
# starting at position a0
# with a1 being the end (1 past number)
# a0 - begin
# a1 - end
# RETURNS:
# a0 - value
parse_int_range:
    li      t1,10
    mv      t2,a0
    mv      t3,a1
    li      a0,0
    li      a1,0
    j       parse_int_loop
parse_int_range_loop_iter:
    addi    t2,t2,1
parse_int_range_loop:
    beq     t2,t3,parse_int_done
    lb      a1,(t2)
    addi    a1,a1,-ZERO
    mul     a0,a0,t1
    add     a0,a0,a1
    j       parse_int_loop_iter
parse_int_range_done:
    ret

# Parses a string to an integer
# but only with the start of the number
# parses until the end of the number (!is_digit)
# a0 - start of number
# undefined behavior if the number goes
# off the end of the string
# RETURNS:
# a0 - value
# a1 - pointer to end of number (1 past the end)
parse_int:
    li      t4,10
    mv      t5,a0
    li      a0,0
    li      a1,0
    j       parse_int_loop
parse_int_loop_iter:
    addi    t5,t5,1
parse_int_loop:
    lb      a1,(t5)
    
    slti    t0,a1,ZERO # is_digit inlined
    xori    t0,t0,1
    slti    t1,a1,COLON
    and     t3,t0,t1
    beqz    t3,parse_int_done # if !is_digit break

    addi    a1,a1,-ZERO # otherwise keep parsing int
    mul     a0,a0,t4
    add     a0,a0,a1
    j       parse_int_loop_iter
parse_int_done:
    mv a1,t5 # ptr to 1 past the number (end)
    ret

# fill_range: TODO - make this function
