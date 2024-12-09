#include "macros.S"
    .global day9_part1,day9_part2 # this file
    .global printf,malloc,memset # libc
    .global is_digit,string_eq,parse_int_range # begin utility.S
    .global parse_int,sort_int,part1_fmt,part2_fmt
    .global grid_load_neighbor_offsets,grid_find_width
    .global unreachable # end utility.S

    .equ ZERO,'0' # ascii 0

    .text

# basically going to iterate through, and when we hit spaces
# come in from the right further counting down
day9_part1:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr
    addi s2,s2,-1 # put s2 at the last element

    li s3,0 # file_index
    slli s4,a1,1 # len / 2 aka end_file_idx
    li s5,0 # pos index

    lb a7,(s2) # number of max_file_idxs
    addi a7,a7,-ZERO # make it an actual integer

d9p1_loop:
    bge s1,s2,d9p1_done # when s1 >= s2 we're done
d9p1_file: # just for organization
    lb a0,(s1) # number of spaces for file idx s3
    addi a0,a0,-ZERO # make it an actual integer
    addi s1,s1,1 # input_ptr += 1
d9p1_file_loop:
    beqz a0,d9p1_empty
    mul t0,s3,s5 # multiply file_idx by pos_idx
    add s0,s0,t0 # add to result
    addi s5,s5,1 # increment pos idx
    addi a0,a0,-1
    j d9p1_file_loop
d9p1_empty:
    lb a0,(s1) # amount of empty space to fill in
    addi a0,a0,-ZERO # make it an actual integer
    addi s1,s1,1
d9p1_empty_loop:
    beqz a0,d9p1_file
    beqz a7,d9p1_next_max
    mul t0,s4,s5 # max_file_idx * pos_idx
    add s0,s0,t0 # add it to result
    addi s5,s5,1 # increment pos idx
    addi a0,a0,-1 # decrement empty space value
    addi a7,a7,-1 # decrement max file value
    j d9p1_empty_loop
d9p1_next_max:
    addi s2,s2,-2 # decrement end ptr, skipping empty space
    lb a7,(s2) # load the next value
    addi a7,a7,-1 # make it an actual integer
    addi s4,s4,-1 # decrement the max value
    j d9p1_empty_loop
d9p1_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

day9_part2:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr


d9p2_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

day9_die:
    call unreachable


    .data # any useful globals (r/w)
