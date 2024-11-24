    .global part1,printf

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
    li a5,0x0a
loop_outer:
    bge a0,a6,done
    li t0,0 # values are guaranteed to exist so no need to check -1
    li t1,0
loop_inner_start_value:
    lb t2,(a0)
    addi a0,a0,1
    li t5,48 # 0 in ascii
    slt t3,t5,t2
    slti t4,t2,58 # colon in ascii (one more than 9)
    and t3,t3,t4
    beqz t3,loop_inner_start_value
    mv t0,t2
    mv t1,t2
loop_inner_end_value:
    lb t2,(a0)
    addi a0,a0,1
    beq t2,a5,loop_inner_add_result # found end of line

    slt t3,t5,t2
    slti t4,t2,58
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


# This is an _internal_ function, so make sure to call
# it with t0 as the return address
# saves off ra and t0 and calls printf
# with whatever a0 and a1 was set to
# idk thought it's a cool thing about riscv
print_result:
    addi sp,sp,-16
    sw ra,16(sp)
    sw t0,8(sp)
    call printf
    lw t0,8(sp)
    lw ra,16(sp)
    addi sp,sp,16
    jr t0

    .section .rodata
fmt1:    .string "part1: %d\n"
