    .global day4_part1,day4_part2

    .equ    COLON, 58
    .equ    PIPE, 124
    .equ    NEWLINE, 0x0a

    .text
#plan: iterate first line parsing number of winning numbers
# I know it's fixed, but it's a different amount between the
# test case and the real data then create an array on the stack for
# the winning numbers. Load winning numbers into that array, then
# check for each number we have if it's a winning number
# easy
# part 2 will just require an array of multipliers
# input:
# a0 - input pointer
# a1 - input length
day4_part1:
    beqz    a1,d4p1_done_early
    addi    sp,sp,-32                             # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)

    li      s0,0                                  # the sum of the points
    mv      s1,a0                                 # put our input pointer in s1 to save across calls
    add     s2,a0,a1                              # put end pointer in s2 to save across calls
    li      s3,0                                  # this will be how much stack we have to unwind

d4p1_determine_array_size:
d4p1_find_colon:
    addi    a0,a0,1
    lb      t0,(a0)
    addi    t0,t0,-COLON
    bnez    t0,d4p1_find_colon
    li      a7,0
    mv      a6,a0                                 # use a6 because a0 is for is_digit
d4p1_find_next_digit:
    addi    a6,a6,1                               # input += 1
    lb      a0,(a6)                               # a0 = *input
    addi    a1,a0,-PIPE                           # if we hit a | we're done
    beqz    a1,d4p1_determine_array_size_end
    call    is_digit                              # otherwise keep looking for digits
    beqz    a0,d4p1_find_next_digit               # not a digit or pipe, keep searching
    addi    a7,a7,1                               # found a number
d4p1_find_end_number:
    addi    a6,a6,1
    lb      a0,(a6)
    call    is_digit
    bnez    a0,d4p1_find_end_number                  # keep going until we are 1 past number
    j       d4p1_find_next_digit                  # there's at least 1 space between end of number and the |
d4p1_determine_array_size_end:
    slli    a7,a7,2                               # a7 = a7 * sizeof(int)
    sub     sp,sp,a7                              # grow the stack
    mv      s3,a7                                 # store byte count in s3 to unwind later
    j       d4p1_outer_loop

d4p1_outer_loop:
d4p1_find_colon_2:
    addi    s1,s1,1
    bge s1,s2,d4p1_done
    lb      t0,(s1)
    addi    t0,t0,-COLON
    bnez    t0,d4p1_find_colon_2
    mv      a7,sp                                 # write the values into our stack array
d4p1_find_next_digit_2:
    addi    s1,s1,1
    lb      a0,(s1)
    addi    a1,a0,-PIPE
    beqz    a1,d4p1_check_winning_numbers
    call    is_digit
    beqz    a0,d4p1_find_next_digit_2
    mv      a0,s1                                 # load beginning of number pointer
    call    parse_int
    sw      a0,(a7)                               # write number into stack array
    addi    a7,a7,4                               # next index of stack array
    mv      s1,a1                                 # update s1 to point to beyond the end of this number
    j       d4p1_find_next_digit_2

d4p1_check_winning_numbers: # for this numbers can back up to newline so don't increment first
    li      a7,0                                  # points for this card
    j d4p1_find_next_digit_3
d4p1_find_next_digit_3_incr:
    addi s1,s1,1
d4p1_find_next_digit_3:
    lb      a0,(s1)
    addi    a1,a0,-NEWLINE
    beqz    a1,d4p1_add_points
    call    is_digit
    beqz    a0,d4p1_find_next_digit_3_incr
    mv      a0,s1                                 # at a digit!
    call    parse_int
    mv      s1,a1                                 # update the input pointer
d4p1_check_is_winning:
    mv      a6,sp                                 # current array index ptr
    add     a5,sp,s3                              # end of stack array
    j       d4p1_check_is_winning_loop
d4p1_check_is_winning_loop_incr:
    addi    a6,a6,4                               # index += 1 (ptr += sizeof(int))
d4p1_check_is_winning_loop:
    beq     a6,a5,d4p1_find_next_digit_3          # not a winning number
    lw      t0,(a6)                               # t0 = wins[i]
    bne     a0,t0,d4p1_check_is_winning_loop_incr # check next array element
    beqz    a7,d4p1_first_winning
    li      t0,2
    mul     a7,a7,t0
    j       d4p1_find_next_digit_3
d4p1_first_winning:
    li      a7,1
    j       d4p1_find_next_digit_3

d4p1_add_points:
    add     s0,s0,a7
    j       d4p1_outer_loop

d4p1_done:
    la      a0,d4p1_fmt
    mv      a1,s0
    call    printf

    add     sp,sp,s3                              # fixup alloca'd stack
    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    addi    sp,sp,32
d4p1_done_early:
    ret

day4_part2:
    ret


    .data
d4p1_fmt:
    .string "Part1: %d\n"