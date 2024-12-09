#include "macros.S"
    .global      day6_part1,day6_part2                      # this file
    .global      printf,malloc,memset,memcpy                # libc
    .global      is_digit,string_eq,parse_int_range         # begin utility.S
    .global      parse_int,sort_int,part1_fmt,part2_fmt
    .global      grid_load_neighbor_offsets,grid_find_width
    .global      unreachable                                # end utility.S


    .equ         START, '^'
    .equ         NEWLINE, '\n'
    .equ         HASH, '#'
    .equ         Y, 'Y'

    .text

#
day6_part1:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    mv           s2,a1                                      # save off length for now

    mv           a0,a1                                      # make a copy because we're going to be destructive
    call         malloc                                     # create copy buffer
    beqz         a0,day6_die                                # when malloc fails nothing we can do

# a0 is already dst
    mv           a1,s1                                      # src input
    mv           a2,s2                                      # length
    call         memcpy                                     # a0 is still dest
    mv           s1,a0                                      # we'll use our copy as the input
    add          s2,s1,s2                                   # end of the copy buffer

    mv           a0,s1
    call         grid_find_width
    mv           s3,a0                                      # s3 = width including newline

# setup the directions array
    la           t0,d6_directions
    sub          t1,zero,s3                                 # up (-width)
    sw           t1,(t0)
    addi         t0,t0,4
    li           t1,1                                       # right (+1)
    sw           t1,(t0)
    addi         t0,t0,4
    mv           t1,s3                                      # down (width)
    sw           t1,(t0)
    addi         t0,t0,4
    li           t1,-1                                      # left (-1)
    sw           t1,(t0)

    li           a7,'Y'                                     # arbitrary letter, could be X
    la           a6,d6_directions                           # we start facing up
d6p1_find_start:
    mv           a0,s1                                      # a0 = ptr = start of input
d6p1_find_start_loop: # guaranteed to exist so no need to bounds check
    lb           t0,(a0)                                    # t0 = *ptr
    addi         t0,t0,-START                               # check if t0 == '^'
    beqz         t0,d6p1_travel_grid                        # found start, start travelling grid
    addi         a0,a0,1                                    # otherwise increment ptr
    j            d6p1_find_start_loop                       # continue loop
d6p1_travel_grid:
    sb           a7,(a0)                                    # mark our current position as 'Y'
    lw           t0,(a6)                                    # get current direction offset
    add          t1,a0,t0                                   # t1 = next position
    blt          t1,s1,d6p1_count_travelled                 # bounds check off top of grid
    bge          t1,s2,d6p1_count_travelled                 # bounds check off bottom of grid
    lb           a1,(t1)                                    # a1 = *next
    addi         t2,a1,-NEWLINE                             # when next pos is a newline that means we're off the grid horizontally
    beqz         t2,d6p1_count_travelled
    addi         t2,a1,-HASH                                # is next position a hash?
    beqz         t2,d6p1_rotate_right                       # yes, goto rotate right
    mv           a0,t1                                      # no, move to that space. keep direction
    j            d6p1_travel_grid
d6p1_rotate_right:
    addi         a6,a6,4                                    # go to next element in direction array
    la           t0,d6_directions_end                       # check against end of direction array
    bne          a6,t0,d6p1_travel_grid                     # not the same so we're fine
    la           a6,d6_directions                           # we were at the end, go back to beginning
    j            d6p1_travel_grid

d6p1_count_travelled:
    mv           a0,s1
    li           s0,0
d6p1_count_travelled_loop:
    beq          a0,s2,d6p1_done
    lb           t0,(a0)
    addi         a0,a0,1
    sub          t0,t0,a7                                   # check if *ptr == 'Y'
    bnez         t0,d6p1_count_travelled_loop               # is not so continue
    addi         s0,s0,1                                    # was a space we travelled to so add 1
    j            d6p1_count_travelled_loop
d6p1_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    mv           a0,s1
    call         free                                       # free the copy of the input

    AOC_EPILOGUE
    ret

# We're going to start the _exact_ same way as part 1
# travel the grid marking 'Y's along the path
# the _only_ difference now is we check each 'Y'
# to see if that could become an obstruction
# and we need a new 4 * input_len bool array
# to track if we've visited this location in
# the particular direction we're travelling
# If we ever hit any space from a direction
# twice then we're in a loop, add 1 and continue
# when we get out of the grid then no loop
day6_part2:
    AOC_PROLOGUE
    li           s0,0                                       # result
    mv           s1,a0                                      # input
    mv           s2,a1                                      # save off length for now

    mv           a0,a1                                      # make a copy because we're going to be destructive
    call         malloc                                     # create copy buffer
    beqz         a0,day6_die                                # when malloc fails nothing we can do

# a0 is already dst
    mv           a1,s1                                      # src input
    mv           a2,s2                                      # length
    call         memcpy                                     # a0 is still dest
    mv           s1,a0                                      # we'll use our copy as the input
    mv           s3,s2                                      # get the length ready for our next big buffer
    add          s2,s1,s2                                   # end of the copy buffer into s2 as always

    slli         a0,s3,2                                    # length but make it word size (I don't want to do bitshifting yet)
    call         malloc                                     # this is our "visited" buffer
    beqz         a0,day6_die                                # when malloc fails nothing we can do
    mv           s5,a0                                      # this is our "visited" buffer

    mv           a0,s1
    call         grid_find_width
    mv           s3,a0                                      # s3 = width including newline

# setup the directions array
    la           t0,d6_directions
    sub          t1,zero,s3                                 # up (-width)
    sw           t1,(t0)
    addi         t0,t0,4
    li           t1,1                                       # right (+1)
    sw           t1,(t0)
    addi         t0,t0,4
    mv           t1,s3                                      # down (width)
    sw           t1,(t0)
    addi         t0,t0,4
    li           t1,-1                                      # left (-1)
    sw           t1,(t0)

    li           a7,Y                                       # arbitrary letter, could be X
    la           a6,d6_directions                           # we start facing up
d6p2_find_start:
    mv           a0,s1                                      # a0 = ptr = start of input
d6p2_find_start_loop: # guaranteed to exist so no need to bounds check
    lb           t0,(a0)                                    # t0 = *ptr
    addi         t0,t0,-START                               # check if t0 == '^'
    mv           s4,a0                                      # store off this location, s4 will be the starting location later
    beqz         t0,d6p2_travel_grid                        # found start, start travelling grid
    addi         a0,a0,1                                    # otherwise increment ptr
    j            d6p2_find_start_loop                       # continue loop
d6p2_travel_grid:
    sb           a7,(a0)                                    # mark our current position as 'Y'
    lw           t0,(a6)                                    # get current direction offset
    add          t1,a0,t0                                   # t1 = next position
    blt          t1,s1,d6p2_count_possible_obstructions     # bounds check off top of grid
    bge          t1,s2,d6p2_count_possible_obstructions     # bounds check off bottom of grid
    lb           a1,(t1)                                    # a1 = *next
    addi         t2,a1,-NEWLINE                             # when next pos is a newline that means we're off the grid horizontally
    beqz         t2,d6p2_count_possible_obstructions
    addi         t2,a1,-HASH                                # is next position a hash?
    beqz         t2,d6p2_rotate_right                       # yes, goto rotate right
    mv           a0,t1                                      # no, move to that space. keep direction
    j            d6p2_travel_grid
d6p2_rotate_right:
    addi         a6,a6,4                                    # go to next element in direction array
    la           t0,d6_directions_end                       # check against end of direction array
    bne          a6,t0,d6p2_travel_grid                     # not the same so we're fine
    la           a6,d6_directions                           # we were at the end, go back to beginning
    j            d6p2_travel_grid
d6p2_count_possible_obstructions:
    mv           s7,s1
    li           s6,0
    j            d6p2_cpo_loop
d6p2_cpo_loop_incr:
    addi         s7,s7,1
    addi         s6,s6,1
d6p2_cpo_loop:
    beq          s7,s2,d6p2_done
    beq          s7,s4,d6p2_cpo_loop_incr
    lb           t0,(s7)                                    # check this value
    addi         t0,t0,-Y                                   # is it on the path
    bnez         t0,d6p2_cpo_loop_incr                      # not on path, continue
    mv           a0,s4                                      # setup starting location
    mv           a1,s7                                      # try obstruction here
    mv           a2,s1                                      # beginning of grid
    mv           a3,s2                                      # end of grid
    mv           a4,s5                                      # visited grid
    call         d6_validate_obstruction
    beqz         a0,d6p2_cpo_loop_incr                      # not a loop, continue
    addi         s0,s0,1
    j            d6p2_cpo_loop_incr

d6p2_done:
    la           a0,part2_fmt
    mv           a1,s0
    call         printf

    mv           a0,s1
    call         free                                       # free the copy of the input
    mv           a0,s5
    call         free                                       # free the visited grid

    AOC_EPILOGUE
    ret

day6_die:
    call         unreachable

# Helper procedure - starting from a0 and "north"
# run iterations until either we go off the end or
# our obstruction has been hit twice in the same direction
# a0 - starting location
# a1 - obstruction location
# a2 - beginning of grid (bounds check)
# a3 - end of grid (bounds check)
# a4 - visited grid (validate will zero)
# RETURNS:
# a0 - 1 if loop else 0
d6_validate_obstruction:
    addi         sp,sp,-64
    sw           ra,(sp)
    sw           s0,8(sp)
    sw           s1,16(sp)
    sw           s2,24(sp)
    sw           s3,32(sp)
    sw           s4,40(sp)

    mv           s0,a0                                      # save these off b/c we're going to call memset
    mv           s1,a1
    mv           s2,a2
    mv           s3,a3
    mv           s4,a4

    mv           a0,s4
    li           a1,0
    sub          a2,s3,s2                                   # size of grid
    slli         a2,a2,2                                    # need to be word size
    call         memset

    la           t5,d6_directions                           # we always start going north
d6_validate_obstruction_travel_loop:
    lw           t0,(t5)                                    # get current direction offset
    add          t1,s0,t0                                   # t1 = next position
    blt          t1,s2,d6_validate_obstruction_off_grid     # bounds check off top of grid
    bge          t1,s3,d6_validate_obstruction_off_grid     # bounds check off bottom of grid
    lb           t3,(t1)                                    # t3 = *next
    addi         t2,t3,-NEWLINE                             # when next pos is a newline that means we're off the grid horizontally
    beqz         t2,d6_validate_obstruction_off_grid        # bounds check horizontal off grid

    la           a0,d6_directions                           # get index into visited buffer at element
    sub          a0,t5,a0                                   # byte offset of direction
    srli         a0,a0,2                                    # index into direction array

    sub          a1,t1,s2                                   # offset to our current position
    slli         a1,a1,2                                    # offset into visited buffer
    add          a2,s4,a1                                   # a2 = ptr to element in visited
    add          a2,a2,a0                                   # direction offset
    lb           a3,(a2)
    bnez         a3,d6_validate_obstruction_loop_detected   # we hit the same path in the same direction. its a loop!
    addi         a3,a3,1
    sb           a3,(a2)                                    # increment this direction's value by 1

    beq          t1,s1,d6_validate_obstruction_rotate_right # we hit the obstruction. rotate right
    addi         t2,t3,-HASH                                # is next position a hash?
    beqz         t2,d6_validate_obstruction_rotate_right    # yes, goto rotate right
    mv           s0,t1                                      # no, move to that space. keep direction
    j            d6_validate_obstruction_travel_loop

d6_validate_obstruction_rotate_right:
    addi         t5,t5,4                                    # go to next element in direction array
    la           t0,d6_directions_end                       # check against end of direction array
    bne          t5,t0,d6_validate_obstruction_travel_loop  # not the same so we're fine
    la           t5,d6_directions                           # we were at the end, go back to beginning
    j            d6_validate_obstruction_travel_loop

d6_validate_obstruction_loop_detected:
    li           a0,1
    j            d6_validate_obstruction_done
d6_validate_obstruction_off_grid:
    li           a0,0
d6_validate_obstruction_done:
    lw           ra,(sp)
    lw           s0,8(sp)
    lw           s1,16(sp)
    lw           s2,24(sp)
    lw           s3,32(sp)
    lw           s4,40(sp)
    addi         sp,sp,64
    ret

    .data                                                   # any useful globals (r/w)

d6_directions:
    .space       16, 0                                      # 4 32-bit integers UP,RIGHT,DOWN,LEFT
d6_directions_end:
    .word        0                                          # one past the direction end for looping

