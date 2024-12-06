#include "macros.S"
    .global day6_part1,day6_part2 # this file
    .global printf,malloc,memset,memcpy # libc
    .global is_digit,string_eq,parse_int_range # begin utility.S
    .global parse_int,sort_int,part1_fmt,part2_fmt
    .global grid_load_neighbor_offsets,grid_find_width
    .global unreachable # end utility.S


    .equ START, '^'
    .equ NEWLINE, '\n'
    .equ HASH, '#'

    .text

# 
day6_part1:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    mv s2,a1 # save off length for now

    mv a0,a1 # make a copy because we're going to be destructive
    call malloc # create copy buffer
    beqz a0,day6_die # if malloc fails nothing we can do
    
    # a0 is already dst
    mv a1,s1 # src input
    mv a2,s2 # length
    call memcpy # a0 is still dest
    mv s1,a0 # we'll use our copy as the input
    add s2,s1,s2 # end of the copy buffer

    mv a0,s1
    call grid_find_width
    mv s3,a0 # s3 = width including newline

    # setup the directions array
    la t0,d6_directions
    sub t1,zero,s3 # up (-width)
    sw t1,(t0)
    addi t0,t0,4
    li t1,1 # right (+1)
    sw t1,(t0)
    addi t0,t0,4
    mv t1,s3 # down (width) 
    sw t1,(t0)
    addi t0,t0,4
    li t1,-1 # left (-1)
    sw t1,(t0)

    li a7,'Y' # arbitrary letter, could be X
    la a6,d6_directions # we start facing up
d6p1_find_start:
    mv a0,s1 # a0 = ptr = start of input
d6p1_find_start_loop: # guaranteed to exist so no need to bounds check
    lb t0,(a0) # t0 = *ptr
    addi t0,t0,-START # check if t0 == '^'
    beqz t0,d6p1_travel_grid # found start, start travelling grid
    addi a0,a0,1 # otherwise increment ptr
    j d6p1_find_start_loop # continue loop
d6p1_travel_grid:
    sb a7,(a0) # mark our current position as 'Y'
    lw t0,(a6) # get current direction offset
    add t1,a0,t0 # t1 = next position
    blt t1,s1,d6p1_count_travelled # bounds check off top of grid
    bge t1,s2,d6p1_count_travelled # bounds check off bottom of grid
    lb a1,(t1) # a1 = *next
    addi t2,a1,-NEWLINE # when next pos is a newline that means we're off the grid horizontally
    beqz t2,d6p1_count_travelled
    addi t2,a1,-HASH # is next position a hash?
    beqz t2,d6p1_rotate_right # yes, goto rotate right
    mv a0,t1 # no, move to that space. keep direction
    j d6p1_travel_grid
d6p1_rotate_right:
    addi a6,a6,4 # go to next element in direction array
    la t0,d6_directions_end # check against end of direction array
    bne a6,t0,d6p1_travel_grid # not the same so we're fine
    la a6,d6_directions # we were at the end, go back to beginning
    j d6p1_travel_grid

d6p1_count_travelled:
    mv a0,s1
    li s0,0
d6p1_count_travelled_loop:
    beq a0,s2,d6p1_done
    lb t0,(a0)
    addi a0,a0,1
    sub t0,t0,a7 # check if *ptr == 'Y'
    bnez d6p1_count_travelled_loop # is not so continue
    addi s0,s0,1 # was a space we travelled to so add 1
    j d6p1_count_travelled_loop
d6p1_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    mv a0,s1
    call free # free the copy of the input

    AOC_EPILOGUE
    ret

day6_part2:
    AOC_PROLOGUE

d6p2_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

day6_die:
    call unreachable


    .data # any useful globals (r/w)

d6_directions: .space 16, 0 # 4 32-bit integers UP,RIGHT,DOWN,LEFT
d6_directions_end: .word 0 # one past the direction end for looping