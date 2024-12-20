#include "macros.S"
    .global      day10_part1,day10_part2                    # this file
    .global      printf,malloc,memset                       # libc
    .global      is_digit,string_eq,parse_int_range         # begin utility.S
    .global      parse_int,sort_int,part1_fmt,part2_fmt
    .global      grid_load_neighbor_offsets,grid_find_width
    .global      unreachable,clear_byte_range               # end utility.S

    .equ         ZERO,'0'
    .equ         NINE,'9'

    .text

# Find a 0. Do a BFS from that zero looking for a 9
# Mark each node as "visited" as we add them to the queue
# so if there are multiple paths we don't double count them
# add the score for that 0 to s0 and move on to the next 0
day10_part1:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr
    mv           s3,a1                                      # input size

    slli         a0,s3,2                                    # make a queue with enough capacity
    call         malloc                                     # for the whole grid to avoid resize
    beqz         a0,day10_die                               # also never need to check if full

    mv           s5,a0                                      # we will store in s5,s6,s7 for ptr,head,tail
    li           s6, 0                                      # head index
    li           s7, 0                                      # tail index
    slli         s10,s3,2                                   # queue size

    mv           a0,s3                                      # size for our bool array
    call         malloc                                     # this array has the counts of
    beqz         a0,day10_die                               # reachable 9s as we search
    mv           s4,a0

    li           a1,0                                       # for memset
    mv           a2,s3                                      # bool array size
    call         memset                                     # a0 is still the array

    mv           a0,s1
    call         grid_find_width
    mv           s8,a0                                      # save grid width
    add          sp,sp,-16                                  # 4 directions
    mv           s9,sp

# load directions
    sub          t0,zero,s8                                 # up
    sw           t0,(s9)
    li           t0,1                                       # right
    sw           t0,4(s9)
    sw           s8,8(s9)                                   # down
    li           t0,-1
    sw           t0,12(s9)                                  # left

    mv           a0,s1
    li           a7,'0'
    j            d10p1_find_next_0

d10p1_find_next_0_reset:
    add          s0,s0,a7                                   # add the score for prev 0
    mv           a6,a0                                      # save off current input
    mv           a0,s4
    add          a1,s4,s3
    call         clear_byte_range
    mv           a0,a6                                      # restore input
    li           s6,0                                       # reset the queue
    li           s7,0                                       # make it empty
    li           a7,'0'                                     # character we are looking for
d10p1_find_next_0_incr:
    addi         a0,a0,1
d10p1_find_next_0:
    beq          a0,s2,d10p1_done                           # hit end of input
    lb           a1,(a0)                                    # a1 : = input[a0]
    bne          a1,a7,d10p1_find_next_0_incr               # if a1 != '0' do continue
    add          a6,s5,s7                                   # tail of queue
    sub          a2,a0,s1                                   # offset into input
    sw           a2,(a6)                                    # store in queue
    addi         s7,s7,4                                    # increment tail
    li           a7,0                                       # score for this 0
d10p1_find_reachable_9s:
    beq          s6,s7,d10p1_find_next_0_reset              # queue empty, found all 9s from this 0
    add          t0,s5,s6                                   # head pointer
    lw           a1,(t0)                                    # a1 : = queue.front()
    addi         s6,s6,4                                    # queue.pop_front()
    bne          s6,s10,d10p1_sf0_skip
    li           s6,0                                       # wrap around queue head
d10p1_sf0_skip:
    add          a2,s1,a1                                   # offset into input
    lb           a4,(a2)                                    # our current value e.g. '8'

    mv           a5,s9                                      # start of directions
    addi         a6,s9,16                                   # end of directions
    j            d10p1_check_neighbors

d10p1_check_neighbors_incr:
    addi         a5,a5,4                                    # increment directions
d10p1_check_neighbors:
    beq          a5,a6,d10p1_find_reachable_9s
    lw           t0,(a5)                                    # neighbor offset
    add          t1,a2,t0                                   # check up direction
    blt          t1,s1,d10p1_check_neighbors_incr           # out of bounds
    bge          t1,s2,d10p1_check_neighbors_incr           # out of bounds
    lb           t2,(t1)                                    # get neighbor value
    addi         t3,t2,-1                                   # we only care about neighbors 1 more than current
    bne          t3,a4,d10p1_check_neighbors_incr           # not a valid path
# valid path, so now mark that it's visited
# and either add to the queue, or if it's a 9 just count the score
    add          a3,a1,t0                                   # offset is the same for a bool array as char array
    add          a3,s4,a3                                   # ptr to bool table
    lb           t3,(a3)
    bnez         t3,d10p1_check_neighbors_incr              # already visited, skip
    li           t4,1
    sb           t4,(a3)                                    # mark visited
    addi         t3,t2,-NINE                                # we can move to t2, check if it's a 9
    beqz         t3,d10p1_add_score                         # we hit a 9, just add to score this
    sub          t1,t1,s1                                   # get idx for neighbor input
    add          t2,s5,s7                                   # offset into queue
    sw           t1,(t2)                                    # queue.append(idx)
    addi         s7,s7,4                                    # tail += 1
    bne          s7,s10,d10p1_check_neighbors_incr          # no wraparound
    li           s7,0
    j            d10p1_check_neighbors_incr

d10p1_add_score:
    addi         a7,a7,1                                    # 1 to our score
    j            d10p1_check_neighbors_incr                 # keep checking neighbors


d10p1_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    mv           a0,s5
    call         free
    mv           a0,s4
    call         free

    add          sp,sp,16

    AOC_EPILOGUE
    ret


# Find all 9s in the input, we have an integer array
# that's the same size as the grid. At the same position
# of the 9, mark those as 1 in the int array
# Add all the 9 indexes to the queue
# BFS so doing all 9 positions, then all 8 positions, etc.
# At eadch point, add our current value (e.g. 1 for the 9)
# to a neighbor's integer value. If the previous neighbor
# value was 0, we haven't visited here yet, add that neighbor
# to the queue to expand later in the BFS.
# So as we expand all 9s, we'll get some 2s and 3s etc in some
# 8 positions, and then so on
# when we hit a 0, we just add the current value (# of trails)
# into s0 when the BFS queue is empty we've added all trail counts
# to s0 and we're done
day10_part2:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr
    mv           s3,a1                                      # input size

    slli         a0,s3,2                                    # make a queue with enough capacity
    call         malloc                                     # for the whole grid to avoid resize
    beqz         a0,day10_die                               # also never need to check if full

    mv           s5,a0                                      # we will store in s5,s6,s7 for ptr,head,tail
    li           s6, 0                                      # head index
    li           s7, 0                                      # tail index
    slli         s10,s3,2                                   # queue size

    slli         a0,s3,2                                    # size for our int array
    call         malloc                                     # this array has the counts of
    beqz         a0,day10_die                               # reachable 9s as we search
    mv           s4,a0

    li           a1,0                                       # for memset
    slli         a2,s3,2                                    # int array size
    call         memset                                     # a0 is still the array

    mv           a0,s1
    call         grid_find_width
    mv           s8,a0                                      # save grid width
    add          sp,sp,-16                                  # 4 directions
    mv           s9,sp

# load directions
    sub          t0,zero,s8                                 # up
    sw           t0,(s9)
    li           t0,1                                       # right
    sw           t0,4(s9)
    sw           s8,8(s9)                                   # down
    li           t0,-1
    sw           t0,12(s9)                                  # left


    mv           a0,s1
    li           a7,'9'
    j            d10p2_find_all_9s

d10p2_find_all_9s_incr:
    addi         a0,a0,1
d10p2_find_all_9s:
    beq          a0,s2,d10p2_search_for_0s                  # hit end of input
    lb           a1,(a0)                                    # a1 : = input[a0]
    bne          a1,a7,d10p2_find_all_9s_incr               # if a1 != '9' do continue
    add          a6,s5,s7                                   # tail of queue
    sub          a2,a0,s1                                   # offset into input
    sw           a2,(a6)                                    # store in queue
    addi         s7,s7,4                                    # increment tail
    slli         a2,a2,2                                    # offset into int array
    add          a2,s4,a2                                   # make a2 a pointer into int array
    li           t0,1
    sw           t0,(a2)                                    # make 9s start with the value 1
    bne          s7,s10,d10p2_find_all_9s_incr              # no need to wrap around
    li           s7,0
    j            d10p2_find_all_9s

d10p2_search_for_0s:
    beq          s6,s7,d10p2_done                           # queue empty, found all 0s
    add          a0,s5,s6                                   # head pointer
    lw           a1,(a0)                                    # a1 : = queue.front()
    addi         s6,s6,4                                    # queue.pop_front()
    bne          s6,s10,d10p2_sf0_skip
    li           s6,0                                       # wrap around queue head
d10p2_sf0_skip:
    add          a2,s1,a1                                   # offset into input
    lb           a4,(a2)                                    # our current value e.g. '8'
    slli         a3,a1,2
    add          a3,s4,a3                                   # offset into int array
    lw           a7,(a3)                                    # current value in int array

    mv           a5,s9                                      # start of directions
    addi         a6,s9,16                                   # end of directions
    j            d10p2_check_neighbors

d10p2_check_neighbors_incr:
    addi         a5,a5,4                                    # increment directions
d10p2_check_neighbors:
    beq          a5,a6,d10p2_search_for_0s
    lw           t0,(a5)                                    # neighbor offset
    add          t1,a2,t0                                   # check up direction
    blt          t1,s1,d10p2_check_neighbors_incr           # out of bounds
    bge          t1,s2,d10p2_check_neighbors_incr           # out of bounds
    lb           t2,(t1)                                    # get neighbor value
    addi         t3,t2,1                                    # we only care about neighbors 1 less than current
    bne          t3,a4,d10p2_check_neighbors_incr           # not a valid path
    addi         t3,t2,-ZERO                                # we can move to t2, check if it's a zero
    beqz         t3,d10p2_count_trails                      # we hit a zero, just count this
    sub          t3,t1,s1                                   # make t1 an index value
    slli         t3,t3,2                                    # index into our int array
    add          t3,s4,t3                                   # t3 now offset into int array
    lw           t4,(t3)                                    # current value
    add          t5,t4,a7                                   # add our value to neighbor
    sw           t5,(t3)                                    # and write that back
    bnez         t4,d10p2_check_neighbors_incr              # someone already hit, don't add to queue
    sub          t1,t1,s1                                   # get offset for input
    add          t2,s5,s7                                   # offset into queue
    sw           t1,(t2)                                    # queue.append(idx)
    addi         s7,s7,4                                    # tail += 1
    bne          s7,s10,d10p2_check_neighbors_incr          # no wraparound
    li           s7,0
    j            d10p2_check_neighbors_incr

d10p2_count_trails:
    add          s0,s0,a7                                   # add our current int value
    j            d10p2_check_neighbors_incr

d10p2_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    mv           a0,s5
    call         free
    mv           a0,s4
    call         free

    add          sp,sp,16

    AOC_EPILOGUE
    ret


day10_die:
    call         unreachable


    .data                                                   # any useful globals (r/w)
