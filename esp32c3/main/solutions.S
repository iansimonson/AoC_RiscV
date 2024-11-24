    .global part1,part2,printf

    .equ ZERO, 48
    .equ NINE, 58
    .equ COLON, 59
    .equ NEWLINE, 0x0a

    .text

# a0 -> pointer to the input
# a1 -> length of the input
# find the first digit in the string
# and the last digit in the string
# and slam them together
# e.g. 7 and 7 -> 77
# sum up all calibratino values (separated by newline)
#
# Going to assume there's at least 1 value before hitting
# a newline, otherwise the puzzle is broken
# Also assumes last line has a newline
# ALSO ALSO - string length is to the end of the string
# and does _not_ include a null terminator
part1:
    li a7,0 # result will be in a7
    add a6,a0,a1 # end
    li a5,NEWLINE
loop_outer:
    bge a0,a6,done
    li t0,0 # values are guaranteed to exist so no need to check -1
    li t1,0
loop_inner_start_value:
    lb t2,(a0)
    addi a0,a0,1
    li t5,48 # 0 in ascii
    slt t3,t5,t2
    slti t4,t2,59 # colon in ascii (one more than 9)
    and t3,t3,t4
    beqz t3,loop_inner_start_value
    mv t0,t2
    mv t1,t2
loop_inner_end_value:
    lb t2,(a0)
    addi a0,a0,1
    beq t2,a5,loop_inner_add_result # found end of line

    slt t3,t5,t2
    slti t4,t2,59
    and t3,t3,t4
    beqz t3,loop_inner_end_value
    mv t1,t2
    j loop_inner_end_value
loop_inner_add_result:
    addi t0,t0,-48
    addi t1,t1,-48
    li t2,10
    mul t0,t0,t2
    add t0,t0,t1
    add a7,a7,t0
    j loop_outer

done:
    la a0,fmt1
    mv a1,a7
    call t0,print_result
    ret

# Now we have to check if e.g. "one" is
# in the string
# a0 - input
# a1 - input_size
#
# In this procedure s0 and s1 will be the
# values we are looking for in the inner loop
# we're using a lot of s* registers because
# we were calling printf here and there
# and starting to call other functions like
# string_eq
part2:
    # prologue
    addi sp,sp,-32
    sw ra,0(sp)
    sw fp,4(sp)
    sw s1,8(sp)
    sw s2,12(sp)
    sw s3,16(sp)
    sw s4,20(sp)
    sw s5,24(sp)
    sw s6,28(sp)

    # Initialize our string check table
    la t1,(check_str_arr)
    la t0,one
    sw t0,0(t1)
    la t0,two
    sw t0,4(t1)
    la t0,three
    sw t0,8(t1)
    la t0,four
    sw t0,12(t1)
    la t0,five
    sw t0,16(t1)
    la t0,six
    sw t0,20(t1)
    la t0,seven
    sw t0,24(t1)
    la t0,eight
    sw t0,28(t1)
    la t0,nine
    sw t0,32(t1)

    # we're calling functions so lets use store registers
    li s6,0 # result
    add s5,a0,a1 # s5 is the end of the buffer
    mv s4,a0 # input ptr
    li s3,36 # end offset for string arrays

p2_loop_outer:
    li s0,0
    li s1,0
    bge s4,s5,p2_done
    j p2_loop_inner_start_val
p2_inner_start_val_incr:
    addi s4,s4,1
p2_loop_inner_start_val: # guaranteed to hit _something_ before newline so no need to check
    lb a0,(s4)
    mv a1,a0
    call is_digit
    beqz a0,p2_inner_start_val_check_str
    addi a1,a1,-ZERO # get actual value
    mv s0,a1 # store it for later
    mv s1,a1 # store end val in case we dont find another
    j p2_inner_end_val_incr
p2_inner_start_val_check_str:
    li t5,0 # start offset
    sub s2,s5,s4
    j p2_inner_start_val_check_str_value
p2_inner_start_val_check_str_incr:
    addi t5,t5,4
    beq t5,s3,p2_inner_start_val_incr
p2_inner_start_val_check_str_value:
    mv a0,s4
    la t4,(check_str_arr)
    la t6,(len_arr)
    add t4,t4,t5
    add t6,t6,t5
    lw a2,(t4)
    lw a3,(t6)
    blt s2,a3,p2_inner_start_val_check_str_incr
    mv a1,a3
    call string_eq
    beqz a0,p2_inner_start_val_check_str_incr # didn't match, check next str
    la t4,(value_arr)
    add t4,t4,t5
    lw s0,(t4) # set start and end values to value_arr[t5]
    lw s1,(t4)
    # no need to jump, we want to skip ahead here
p2_inner_end_val_incr:
    addi s4,s4,1
p2_inner_end_val: # not used but keeping the symmetry to above
    lb a0,(s4)
    li t0,NEWLINE
    beq a0,t0,p2_inner_add_result
    mv a1,a0
    call is_digit
    beqz a0,p2_inner_end_val_check_str
    addi a1,a1,-ZERO
    mv s1,a1
    j p2_inner_end_val_incr # need to keep going until end of line
p2_inner_end_val_check_str:
    li t5,0
    sub s2,s5,s4
    j p2_inner_end_val_check_str_value
p2_inner_end_val_check_str_incr:
    addi t5,t5,4
    beq t5,s3,p2_inner_end_val_incr
p2_inner_end_val_check_str_value:
    mv a0,s4
    la t4,(check_str_arr)
    la t6,(len_arr)
    add t4,t4,t5
    add t6,t6,t5
    lw a2,(t4)
    lw a3,(t6)
    blt s2,a3,p2_inner_end_val_check_str_incr
    mv a1,a3
    call string_eq
    beqz a0,p2_inner_end_val_check_str_incr
    la t4,(value_arr)
    add t4,t4,t5
    lw s1,(t4)
    j p2_inner_end_val_incr

p2_inner_add_result:
    # la a0,dbg2
    # mv a1,s0
    # mv a2,s1
    # call printf
    li t2,10
    mul s0,s0,t2
    add s0,s0,s1
    add s6,s6,s0
    addi s4,s4,1
    j p2_loop_outer

p2_done:
    la a0,fmt2
    mv a1,s6
    call t0,print_result

    #epilogue
    lw ra,0(sp)
    lw fp,4(sp)
    lw s1,8(sp)
    lw s2,12(sp)
    lw s3,16(sp)
    lw s4,20(sp)
    lw s5,24(sp)
    lw s6,28(sp)
    addi sp,sp,32
    ret


# returns true if char is an ascii digit
# a0 - byte
is_digit:
    slti t0,a0,ZERO
    xori t0,t0,1
    slti t1,a0,COLON
    and a0,t0,t1
    ret

# Compare two strings
# a0 - data1
# a1 - len1
# a2 - data2
# a3 - len2
string_eq:
    bne a1,a3,done_false
string_eq_loop:
    beqz a1,done_true
    lb t0,(a0)
    lb t1,(a2)
    bne t0,t1,done_false
    addi a0,a0,1
    addi a2,a2,1
    addi a1,a1,-1
    j string_eq_loop
done_true:
    li a0,1
    ret
done_false:
    li a0,0
    ret


# This is an _internal_ function, so make sure to call
# it with t0 as the return address
# saves off ra and t0 and calls printf
# with whatever a0 and a1 was set to
# idk thought it's a cool thing about riscv
print_result:
    addi sp,sp,-16
    sw ra,8(sp)
    sw t0,0(sp)
    call printf
    lw t0,0(sp)
    lw ra,8(sp)
    addi sp,sp,16
    jr t0

    .data
check_str_arr: .space 36

    .section .rodata
fmt1:    .string "part1: %d\n"
fmt2:    .string "part2: %d\n"
dbg2:    .string "v1: %d, v2: %d\n"

one:    .string "one"
two:    .string "two"
three:    .string "three"
four:    .string "four"
five:    .string "five"
six:    .string "six"
seven:    .string "seven"
eight:    .string "eight"
nine:    .string "nine"

len_arr:
one_len: .word 3
two_len: .word 3
three_len: .word 5
four_len: .word 4
five_len: .word 4
six_len: .word 3
seven_len: .word 5
eight_len: .word 5
nine_len: .word 4

value_arr:
one_value: .word 1
two_value: .word 2
three_value: .word 3
four_value: .word 4
five_value: .word 5
six_value: .word 6
seven_value: .word 7
eight_value: .word 8
nine_value: .word 9

