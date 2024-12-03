    .global day2_part1,day2_part2,printf,parse_int

    .equ    NEWLINE, 0x0a

    .text

# outer loop (newlines) to start over
# parse first number
# loop:
day2_part1:
    addi    sp,sp,-64                              # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)
    sd      s4,40(sp)
    sd      s5,48(sp)

    li      s0,0                                   # result
    mv      s1,a0                                  # pointer
    add     s2,a0,a1                               # end
    j       d2p1_outer_loop

d2p1_outer_loop_incr:
    addi    s1,s1,1                                # input += 1
d2p1_outer_loop:
    beq     s1,s2,d2p1_done                        # break if input > end
    li      a7,1                                   # a7 is each step between 1 and 3
    li      s4,0                                   # s4 = "numbers decreased at some point"
    li      s5,0                                   # s5 = "numbers increased at some point"
# we need s4 xor s5 == 1 at end of line
# we won't skip to newline early b/c extra work
    mv      a0,s1                                  # a0 = input
    call    parse_int
    mv      s3,a0                                  # prev value
    mv      s1,a1                                  # update input (*input is a space)
d2p1_inner_loop:
    beq     s1,s2,d2p1_inner_loop_done
    lb      t0,(s1)
    addi    t0,t0,-NEWLINE
    beqz    t0,d2p1_inner_loop_done
    addi    s1,s1,1                                # now a digit
    mv      a0,s1
    call    parse_int
    mv      s1,a1                                  # update pointer
    slt     t0,a0,s3                               # is decreasing
    slt     t1,s3,a0                               # is increasing
    or      s4,s4,t0                               # we'll make s4 the "is decreasing"
    or      s5,s5,t1                               # and s5 is "is increasing"
    sub     a1,a0,s3                               # a1 = a0 - s3
    bgez    a1,d2p1_skip_neg
    neg     a1,a1                                  # abs(a0 - s3)
d2p1_skip_neg:
    slti    t0,a1,4                                # diff <= 3? (diff < 4)
    li      t2,0                                   # because there is no sgei
    slt     t1,t2,a1                               # diff >= 1? (0 < diff)
    and     t0,t0,t1                               # both must be true
    and     a7,a7,t0                               # a7 is "is safe"
    mv      s3,a0                                  # update s3 with prev value
    j       d2p1_inner_loop
d2p1_inner_loop_done:
    xor     t0,s4,s5                               # can only be increasing or decreasing
    beqz    t0,d2p1_outer_loop_incr                # had both or neither
    beqz    a7,d2p1_outer_loop_incr                # diff of values not 1 <= diff <= 3
    addi    s0,s0,1                                # otherwise SAFE, add 1
    j       d2p1_outer_loop_incr
d2p1_done:
    la      a0,d2p1_fmt
    mv      a1,s0
    call    printf

    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    ld      s4,40(sp)
    ld      s5,48(sp)
    addi    sp,sp,64                               # epilogue
    ret

# bleh cases where a number is valid
# but actually it's the number we have
# to remove to make the rest valid
# so. yeah we'll have to parse and validate
# the array with 1 element skipping...probably a better
# way
day2_part2:
    addi    sp,sp,-64                              # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)
    sd      s4,40(sp)
    sd      s5,48(sp)

    li      s0,0                                   # result
    mv      s1,a0                                  # pointer
    add     s2,a0,a1                               # end
    li      s3,0                                   # array size bytes
    j       d2p2_outer_loop

d2p2_outer_loop_incr:
    add     sp,sp,s3                               # reset the stack
    li      s3,0                                   # no elements now
    addi    s1,s1,1                                # input += 1
d2p2_outer_loop:
    beq     s1,s2,d2p2_done                        # break if input > end
d2p2_parse_to_array:
    mv      a0,s1                                  # a0 = input
    call    parse_int
    mv      s1,a1                                  # update input (*input is a space)
    li      s3,4                                   # stack amount we're using
    addi    sp,sp,-4                               # allocate some stack space
    sw      a0,(sp)                                # it's ok to store the array in reverse order
d2p2_parse_array_inner_loop:
    beq     s1,s2,d2p2_parse_array_inner_loop_done # input >= end, done
    lb      t0,(s1)
    addi    t0,t0,-NEWLINE
    beqz    t0,d2p2_parse_array_inner_loop_done    # *input == '/n' done with line
    addi    s1,s1,1                                # now a digit
    mv      a0,s1
    call    parse_int
    mv      s1,a1                                  # update pointer
    addi    s3,s3,4                                # save how much stack we're using
    addi    sp,sp,-4                               # allocate more stack space
    sw      a0,(sp)                                # store the parsed int
    j       d2p2_parse_array_inner_loop            # no need to check if diff ok
d2p2_parse_array_inner_loop_done: # we have the values as an int array
    srli    a7,s3,2                                # get array count
    mv      a6,a7                                  # a6 = index to skip
d2p2_check_list_loop_incr:
    addi    a6,a6,-1                               # len - 1 (last element)
d2p2_check_list_loop:
    bltz    a6,d2p2_check_list_done
    mv      a0,a7
    mv      a1,a6
    call    is_safe
    beqz    a0,d2p2_check_list_loop_incr           # if not valid, try another index
    addi    s0,s0,1                                # otherwise this loop is good! move on to next group
d2p2_check_list_done:
    j       d2p2_outer_loop_incr
d2p2_done:
    la      a0,d2p2_fmt
    mv      a1,s0
    call    printf

    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    ld      s4,40(sp)
    ld      s5,48(sp)
    addi    sp,sp,64                               # epilogue
    ret

# sp - beginning of array
# a0 - length (in ints)
# a1 - index to skip
# returns a0 - true/false
is_safe:
    li      a2,0                                   # index to check
    li      t0,0                                   # is increasing
    li      t1,0                                   # is decreasing
    li      t3,1                                   # diffs ok
    li      a3,-1                                  # previous value in a3, set to "unset"
    j       is_safe_loop
is_safe_loop_incr:
    addi    a2,a2,1
is_safe_loop:
    beq     a2,a0,is_safe_done                     # end of loop
    beq     a2,a1,is_safe_loop_incr                # skip the particular index
    slli    t4,a2,2                                # byte offset
    add     t4,sp,t4                               # t4 is now array + i
    lw      t4,(t4)                                # t4 = array[i]
    bltz    a3,is_safe_loop_first_number           # if a3 < 0, first number we care about
    slt     t5,t4,a3                               # is decreasing
    or      t0,t0,t5                               # or it into t0
    slt     t5,a3,t4                               # is increasing
    or      t1,t1,t5                               # or it inot t1

    sub     t5,t4,a3                               # t5 = t4 - a3
    bgez    t5,is_safe_skip_neg
    neg     t5,t5                                  # abs(t4 - a3)
is_safe_skip_neg:
    mv      a3,t4                                  # update prev so we can reuse t4
    slti    t4,t5,4                                # diff <= 3? (diff < 4)
    li      t6,0                                   # because there is no sgei
    slt     t6,t6,t5                               # diff >= 1? (0 < diff)
    and     t4,t4,t6                               # both must be true
    and     t3,t3,t4                               # t3 is "diffs ok"
    j       is_safe_loop_incr
is_safe_loop_first_number:
    mv      a3,t4                                  # just set the value, don't check increase, decrease, or diff
    j       is_safe_loop_incr
is_safe_done:
    xor     t0,t0,t1                               # make sure we're only increasing or decreasing
    and     a0,t0,t3                               # were all diffs ok, and only increasing or decreasing
    ret

    .data
d2p1_fmt:
.string "Part1: %d\n"
d2p2_fmt:
.string "Part2: %d\n"
