    .global day2_part1,day2_part2,printf,parse_int

    .equ    NEWLINE, 0x0a

    .text

# outer loop (newlines) to start over
# parse first number
# loop: 
day2_part1:
    addi    sp,sp,-64                             # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)
    sd      s4,40(sp)
    sd      s5,48(sp)

    li s0,0 # result
    mv s1,a0 # pointer
    add s2,a0,a1 # end
    j d2p1_outer_loop

d2p1_outer_loop_incr:
    addi s1,s1,1 # input += 1
d2p1_outer_loop:
    beq s1,s2,d2p1_done # break if input > end
    li a7,1 # a7 is each step between 1 and 3
    li s4,0 # s4 = "numbers decreased at some point"
    li s5,0 # s5 = "numbers increased at some point"
    # we need s4 xor s5 == 1 at end of line
    # we won't skip to newline early b/c extra work
    mv a0,s1 # a0 = input
    call parse_int
    mv s3,a0 # prev value
    mv s1,a1 # update input (*input is a space)
d2p1_inner_loop:
    lb t0,(s1)
    addi t0,t0,-NEWLINE
    beqz d2p1_inner_loop_done
    addi s1,s1,1 # now a digit
    mv a0,s1
    call parse_int
    mv s1,a1 # update pointer
    slt t0,a0,s3 # is decreasing
    slt t1,s3,a0 # is increasing
    or s4,s4,t0 # we'll make s4 the "is decreasing"
    or s5,s5,t1 # and s5 is "is increasing"
    sub a1,a0,s3 # a1 = a0 - s3
    bgez a1,d2p1_skip_neg
    neg a1,a1 # abs(a0 - s3)
d2p1_skip_neg:
    slti t0,a1,4 # diff <= 3? (diff < 4)
    li t2,0 # because there is no sgei
    slt t1,t2,a1 # diff >= 1? (0 < diff)
    and t0,t0,t1 # both must be true
    and a7,a7,t0 # a7 is "is safe"
    mv s3,a0 # update s3 with prev value
    j d2p1_inner_loop
d2p1_inner_loop_done:
    xor t0,s4,s5 # can only be increasing or decreasing
    beqz d2p1_outer_loop_incr # had both or neither
    beqz a7,d2p1_outer_loop_incr # diff of values not 1 <= diff <= 3
    addi s0,s0,1 # otherwise SAFE, add 1
d2p1_done:
    la a0,d2p1_fmt
    mv a1,s0
    call printf

    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    ld      s4,40(sp)
    ld      s5,48(sp)
    addi    sp,sp,64                              # epilogue
    ret

day2_part2:
    ret

    .data:
d2p1_fmt: .string "Part1: %d\n"
d2p1_fmt: .string "Part2: %d\n"