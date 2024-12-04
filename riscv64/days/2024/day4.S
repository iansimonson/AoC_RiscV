# unsure why include works but .include doesn't, probably something with how gcc
# places the files after running cpp?
#include "macros.S"

    .global      day4_part1,day4_part2               # this file produces
    .global      part1_fmt,part2_fmt,grid_find_width # from utility.S
    .global      grid_load_neighbor_offsets          # from utility.S
    .global      printf                              # from libc

    .equ         X, 'X'                              # 0x58
    .equ         M, 'M'                              # 0x4D
    .equ         A, 'A'                              # 0x41
    .equ         S, 'S'                              # 0x53
    .equ         XMAS, 0x584D4153                    # XMAS with X in the highest 8 bits


# look for X
# then check neighbor directions
# to see if we can go in that direction
# 3 more spaces (MAS)
# for left and right we can just lw instead
# of lb each character
# a0 - input
# a1 - length
day4_part1:
    beqz         a1,d4p1_done_early
    AOC_PROLOGUE

    li           s0,0                                # result
    mv           s1,a0                               # input ptr
    add          s2,a0,a1                            # end ptr for bounds checking
    mv           s5,a0                               # begin ptr for bounds checking

    call         grid_find_width                     # a0 is now the grid width
    mv           s3,a0                               # save the width into s3, will need for neighbors
    addi         sp,sp,-32                           # 8 * sizeof(int32_t) for neighbor directions
    mv           s4,sp                               # pointer to the array of neighbor offsets
    mv           a0,s4                               # load array pointer for call
    mv           a1,s3                               # load grid width for call
    call         grid_load_neighbor_offsets          # offsets to each neighbor we will loop through

    li           a7,X                                # for comparisons
    j            d4p1_outer_loop

d4p1_outer_loop_incr:
    addi         s1,s1,1
d4p1_outer_loop: # loop until we find an 'X'
    beq          s1,s2,d4p1_done                     # break if input == end
    lb           a0,(s1)                             # a0 = *input
    bne          a0,a7,d4p1_outer_loop_incr          # skip until we find an X
    li           t0,0                                # index through neighbors
    li           t5,32                               # size of neighbor index (8 * sizeof(int32_t))
    j            d4p1_check_each_neighbor
d4p1_check_each_neighbor_incr:
    addi         t0,t0,4
d4p1_check_each_neighbor:
    beq          t0,t5,d4p1_outer_loop_incr          # move on to next X if checked every neighbor
    add          a1,s4,t0                            # neighbors_arr + offset
    lw           a1,(a1)                             # get the offset itself
    li           t1,3
    mul          a2,a1,t1                            # 3 * offset, we need to make sure it's in-bounds
    add          t2,s1,a2
    blt          t2,s5,d4p1_check_each_neighbor_incr
    bge          t2,s2,d4p1_check_each_neighbor_incr # if the S would be out of bounds, skip direction
    li           a0,X                                # we were reusing a0 so make it X now just in case
# a0 == 'X' right now in low bytes
# so lets just << 8 unsigned and or in next byte
    slli         a0,a0,8
    add          t1,s1,a1                            # pointer now at M maybe
    lb           t2,(t1)                             # t2 = *(input + offset)
    or           a0,a0,t2                            # a0 is now maybe XM
    slli         a0,a0,8
    add          t1,t1,a1                            # pointer now at A maybe
    lb           t2,(t1)
    or           a0,a0,t2                            # a0 is now maybe XMA
    slli         a0,a0,8
    add          t1,t1,a1
    lb           t2,(t1)
    or           a0,a0,t2                            # a0 is now maybe XMAS
    li           t2,XMAS
    sub          a0,a0,t2                            # a0 - XMAS
    bnez         a0,d4p1_check_each_neighbor_incr    # not XMAS check next neighbor
    addi         s0,s0,1                             # was XMAS add 1
    j            d4p1_check_each_neighbor_incr
d4p1_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    addi         sp,sp,32                            # give back array for neighbor directions
    AOC_EPILOGUE
d4p1_done_early:
    ret


# OK sounds easy enough, we're just looking for As instead
# and checking that there are 2 Ms on the diagonals
# and then that the opposite diagonal neighbor is an S
day4_part2:
    AOC_PROLOGUE                                     # just save off all necessary registers so we can use everything

    li           s0,0                                # result
    mv           s1,a0                               # input ptr
# I always use s2 as "end" so even though this seems backwards
# it is consistent and therefore better
    add          s2,a0,a1                            # end ptr for bounds checking
    mv           s3,a0                               # begin ptr for bounds checking

    call         grid_find_width                     # a0 is now the grid width
    mv           s4,a0                               # save the width into s4, will need for neighbors
    addi         sp,sp,-32                           # 8 * sizeof(int32_t) for neighbor directions
    mv           s5,sp                               # pointer to the array of neighbor offsets
    mv           a0,s5                               # load array pointer for call
    mv           a1,s4                               # load grid width for call
    call         grid_load_neighbor_offsets          # offsets to each neighbor we will loop through

    li           a7,A                                # for comparisons
    j            d4p2_outer_loop

d4p2_outer_loop_incr:
    addi         s1,s1,1
d4p2_outer_loop:
    beq          s1,s2,d4p2_done                     # break if input == end
    lb           a0,(s1)                             # a0 = *input
    bne          a0,a7,d4p2_outer_loop_incr          # skip until we find an A
    li           a6,M
    addi         a6,a6,S                             # a6 is the sum of M+S
    j            d4p2_check_diagonal1
d4p2_check_diagonal1: # label just for organization
    li           a4,0                                # true if diagonals are M or S
    lw           t0,0(s5)                            # top left offset
    add          a1,s1,t0                            # ptr to top left neighbor
    blt          a1,s3,d4p2_outer_loop_incr          # out of bounds, not possible to have an X shape
    lb           t0,(a1)                             # t0 = character
    addi         t1,t0,-M
    seqz         t1,t1                               # set t1 true if 'M'
    addi         t2,t0,-S
    seqz         t2,t2                               # set t2 to true if 'S'
    or           a4,t1,t2                            # a4 = true if the upper left is M or S
    mv           a5,t0                               # move the character into a5 for later use
    lw           t0,28(s5)                           # bottom right offset
    add          a1,s1,t0                            # ptr to bottom right neighbor
    bge          a1,s2,d4p2_outer_loop_incr          # out of bounds, no X here
    lb           t0,(a1)
    addi         t1,t0,-M
    seqz         t1,t1                               # set t1 true if 'M'
    addi         t2,t0,-S
    seqz         t2,t2                               # set t2 to true if 'S'
    or           t1,t1,t2                            # t1 = true if the diagonal is M or S
    and          a4,a4,t1                            # make sure _both_ neighbors are M or S
    beqz         a4,d4p2_outer_loop_incr             # not valid, move on
    add          a5,a5,t0                            # sum the characters together
    bne          a5,a6,d4p2_outer_loop_incr          # c1 + c2 != M + S so could be S + S. not an X-MAS
d4p2_check_diagonal2: # label just for organization
    lw           t0,8(s5)                            # top right offset
    add          a1,s1,t0                            # ptr to top left neighbor
    blt          a1,s3,d4p2_outer_loop_incr          # out of bounds, not possible to have an X shape
    lb           t0,(a1)                             # t0 = character
    addi         t1,t0,-M
    seqz         t1,t1                               # set t1 true if 'M'
    addi         t2,t0,-S
    seqz         t2,t2                               # set t2 to true if 'S'
    or           a4,t1,t2                            # a4 = true if the upper left is M or S
    mv           a5,t0                               # move the character into a5 for later use
    lw           t0,20(s5)                           # bottom left offset
    add          a1,s1,t0                            # ptr to bottom right neighbor
    bge          a1,s2,d4p2_outer_loop_incr          # out of bounds, no X here
    lb           t0,(a1)
    addi         t1,t0,-M
    seqz         t1,t1                               # set t1 true if 'M'
    addi         t2,t0,-S
    seqz         t2,t2                               # set t2 to true if 'S'
    or           t1,t1,t2                            # t1 = true if the diagonal is M or S
    and          a4,a4,t1                            # make sure _both_ neighbors are M or S
    beqz         a4,d4p2_outer_loop_incr             # not valid, move on
    add          a5,a5,t0                            # sum the characters together
    bne          a5,a6,d4p2_outer_loop_incr          # c1 + c2 != M + S so could be S + S. not an X-MAS
d4p2_found_XMAS:
    addi         s0,s0,1                             # we found an X-MAS!
    j            d4p2_outer_loop_incr
d4p2_done:
    la           a0,part2_fmt
    mv           a1,s0
    call         printf

    addi         sp,sp,32
    AOC_EPILOGUE                                     # restore all registers saved off in prologue
    ret

