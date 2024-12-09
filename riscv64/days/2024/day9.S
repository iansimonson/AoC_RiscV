#include "macros.S"
    .global      day9_part1,day9_part2                      # this file
    .global      printf,malloc,memset                       # libc
    .global      is_digit,string_eq,parse_int_range         # begin utility.S
    .global      parse_int,sort_int,part1_fmt,part2_fmt
    .global      grid_load_neighbor_offsets,grid_find_width
    .global      unreachable                                # end utility.S

    .equ         ZERO,'0'                                   # ascii 0

    .text

# basically going to iterate through, and when we hit spaces
# come in from the right further counting down
day9_part1:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr
    addi         s2,s2,-1                                   # put s2 at the last element

    li           s3,0                                       # file_index
    srli         s4,a1,1                                    # len / 2 aka end_file_idx
    li           s5,0                                       # pos index

    lb           a7,(s2)                                    # number of max_file_idxs
    addi         a7,a7,-ZERO                                # make it an actual integer

d9p1_loop:
    bge          s1,s2,d9p1_remaining                       # when s1 >= s2 we're done
d9p1_file: # just for organization
    lb           a0,(s1)                                    # number of spaces for file idx s3
    addi         a0,a0,-ZERO                                # make it an actual integer
    addi         s1,s1,1                                    # input_ptr += 1
# I originally just looped here, but in p2 realized
# I can replace this loop with math
    mul          a1,a0,a0                                   # n * n
    sub          a1,a1,a0                                   # n * n - n
    srli         a1,a1,1                                    # / 2
    mul          a2,a0,s5                                   # n * cur_pos_idx
    add          a1,a1,a2                                   # sum those
    mul          a1,a1,s3                                   # multiply by the file idx
    add          s0,s0,a1                                   # add that into sum
    add          s5,s5,a0                                   # add n to cur_pos
    addi         s3,s3,1                                    # increment file index for next loop
d9p1_empty:
    lb           a0,(s1)                                    # amount of empty space to fill in
    addi         a0,a0,-ZERO                                # make it an actual integer
    addi         s1,s1,1
d9p1_empty_loop:
    beqz         a0,d9p1_loop
    beqz         a7,d9p1_next_max
    mul          t0,s4,s5                                   # max_file_idx * pos_idx
    add          s0,s0,t0                                   # add it to result
    addi         s5,s5,1                                    # increment pos idx
    addi         a0,a0,-1                                   # decrement empty space value
    addi         a7,a7,-1                                   # decrement max file value
    j            d9p1_empty_loop
d9p1_next_max:
    addi         s2,s2,-2                                   # decrement end ptr, skipping empty space
    blt          s2,s1,d9p1_done                            # end pointer less than begin, done
    lb           a7,(s2)                                    # load the next value
    addi         a7,a7,-ZERO                                # make it an actual integer
    addi         s4,s4,-1                                   # decrement the max value
    j            d9p1_empty_loop
d9p1_remaining: # whatever is left of our end_idx we need to calc here
    beqz         a7,d9p1_done
    mul          t0,s4,s5
    add          s0,s0,t0
    addi         s5,s5,1
    addi         a7,a7,-1
    j            d9p1_remaining
d9p1_done:
    la           a0,d9p1_fmt
    mv           a1,s0
    call         printf

    AOC_EPILOGUE
    ret

# similar to p1 except now we have a bool array
# of files that we have moved over
# loop down the bool array looking for a file that can be moved over
# and if we can, add that into the sum and then mark it as moved
# and then just also check if we're below our current input pointer
day9_part2:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr

    li           s3,0                                       # file_index
    mv           s4,s1                                      # start of input for figuring out our index
    li           s5,0                                       # pos index
    mv           s7,a1                                      # size for memset

    mv           a0,s7
    call         malloc                                     # bool array
    beqz         a0,day9_die                                # no error handling
    mv           s6,a0
    li           a1,0                                       # zero memory
    mv           a2,s7
    call         memset                                     # zero our bool array

d9p2_loop:
    bge          s1,s2,d9p2_done                            # when s1 >= s2 we're done
d9p2_file: # just for organization
    sub          a5,s1,s4                                   # get length
    srli         a5,a5,1                                    # get the index into the bool array
    add          a5,s6,a5                                   # offset into bool array
    lb           a0,(a5)                                    # check if we've compacted this file
    bnez         a0,d9p2_skip_file                          # we did, so skip
    li           a0,1                                       # we're handling the file now so it's "compacted"
    sb           a0,(a5)                                    # so set the bool array
    lb           a0,(s1)                                    # number of spaces for file idx s3
    addi         a0,a0,-ZERO                                # make it an actual integer
# we're going to math in p2 because we can
# given file size n at pos x and file idx y
# we have: (n(n-1)/2 + n * cur_pos_idx) * file_idx
    mul          a1,a0,a0                                   # n * n
    sub          a1,a1,a0                                   # n * n - n
    srli         a1,a1,1                                    # / 2
    mul          a2,a0,s5                                   # n * cur_pos_idx
    add          a1,a1,a2                                   # sum those
    mul          a1,a1,s3                                   # multiply by the file idx
    add          s0,s0,a1                                   # add that into sum
    add          s5,s5,a0                                   # add n to cur_pos
    j            d9p2_incr_idxs
d9p2_skip_file:
    lb           a0,(s1)                                    # we need to update cur_pos also
    addi         a0,a0,-ZERO                                # make it an integer
    add          s5,s5,a0                                   # add n to the cur_pos
d9p2_incr_idxs:
    addi         s3,s3,1                                    # increment file index
    addi         s1,s1,1                                    # input_ptr += 1
d9p2_empty:
    lb           a0,(s1)                                    # amount of empty space to fill in
    addi         a0,a0,-ZERO                                # make it an actual integer
d9p2_find_file: # look for a file that's small enough that we haven't processed yet
    beqz         a0,d9p2_cannot_compact                     # space is zero, skip compacting
    add          a5,s2,-1                                   # previous element
    sub          a6,a5,s4                                   # byte offset from beginning
    srli         a6,a6,1                                    # get file index of this element
    add          a6,s6,a6                                   # pointer into bool array

    addi         a7,s1,-1                                   # prev file pointer
    sub          a7,a7,s4                                   # prev file offset
    srli         a7,a7,1                                    # prev file_index offset
    add          a7,s6,a7                                   # prev pointer into bool array (early return)
    j            d9p2_find_file_loop

d9p2_find_file_loop_decr:
    addi         a6,a6,-1
d9p2_find_file_loop:
    ble          a6,a7,d9p2_cannot_compact                  # no files to compact
    lb           a4,(a6)                                    # check if we have compacted this file
    beqz         a4,d9p2_try_compact_file                   # we have not so see if we can compact file
    j            d9p2_find_file_loop_decr
d9p2_try_compact_file:
    sub          a1,a6,s6                                   # get offset into bool array
    mv           t1,a1                                      # this offset is also the file index
    slli         a1,a1,1                                    # jump to offset into outer array
    add          a1,s4,a1                                   # offset into input array
    lb           a2,(a1)                                    # get the size of this file (n)
    addi         a2,a2,-ZERO                                # make size an integer
    bgt          a2,a0,d9p2_find_file_loop_decr             # too large for space, try next
# file can be compacted fully. add to answer and sub from a0
    li           t0,1
    sb           t0,(a6)                                    # write that we're compacting this file
# basically the same math here
    mul          t2,a2,a2                                   # n * n
    sub          t2,t2,a2                                   # n * n - n
    srli         t2,t2,1                                    # / 2
    mul          t3,a2,s5                                   # n * cur_pos_idx
    add          t2,t2,t3                                   # sum those
    mul          t2,t2,t1                                   # multiply by the file idx of the end file
    add          s0,s0,t2                                   # add that into sum
    add          s5,s5,a2                                   # add n to cur_pos
    sub          a0,a0,a2                                   # remove compacted file size from empty space amount
    beqz         a0,d9p2_cannot_compact                     # done compacting, early skip
    j            d9p2_find_file_loop_decr                   # see if we can compact any other files

d9p2_cannot_compact:
    add          s5,s5,a0                                   # cannot compact, add remaining empty space to pos index
    addi         s1,s1,1                                    # move to the file now
    j            d9p2_loop

d9p2_done:
    la           a0,d9p2_fmt
    mv           a1,s0
    call         printf

    AOC_EPILOGUE
    ret

day9_die:
    call         unreachable


    .data                                                   # any useful globals (r/w)
d9p1_fmt:
    .string      "Part 1: %zu\n"                            # need because it's a u64 not an int
d9p2_fmt:
    .string      "Part 2: %zu\n"
