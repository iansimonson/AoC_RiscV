#include "macros.S"
    .global day11_part1,day11_part2 # this file
    .global printf,malloc,memset # libc
    .global is_digit,string_eq,parse_int_range # begin utility.S
    .global parse_int,sort_int,part1_fmt,part2_fmt
    .global grid_load_neighbor_offsets,grid_find_width
    .global unreachable,count_digits # end utility.S

    .struct 0 # Stone :: struct {
value: .space 4 # actual value of this stone
count: .space 4  # number of stones of this value
    .balign 8 # }
node_sz = . - data # node_sz = sizeof(Int_Map)

    .text
day11_part1:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr

    li s3,8000 # 1k of Stones
    
    # we're going to do a kinda weird thing
    # we'll always have our "from" array in s4:s5
    # and our "to" array in s5:s6
    # so we can swap after simulating

    # we need 2 arrays b/c celular automoton stuff
    mv a0,s3
    call malloc
    beqz a0,day11_die
    mv s4,a0 # store first one in s4
    li s5,0 # number of unique stones in arr1

    # allocate map 2
    mv a0,s3
    call malloc
    beqz a0,day11_die
    mv s6,a0 # store second array in s6
    li s7,0

    mv a7,s4 # setup pointer for parsing input
    li a6,1 # stone count
d11p1_parse_input: # input are all unique numbers no need to do insertion sort
    bge s1,s2,d11p1_simulate
    mv a0,s1
    call parse_int
    addi s1,a1,1 # skip the space
    sw a0,(a7) # store the stone value
    sw a6,4(a7) # store the stone count (1)
    addi a7,a7,8 # arr += 1
    addi s5,s5,1 # num_stones += 1
    j d11p1_parse_input

d11p1_simulate:
    li a7,25 # number of times to simulate
d11p1_simulate_iter:
    beqz a7,d11p1_count_stones
    addi a7,a7,-1
    mv a6,s4 # pointer to the "to" stones array
    mv a5,s6 # pointer to "from" stones array
d11p1_expand_stones:
    beqz s5,d11p1_expanded
    addi s5,s5,-1
    lw t0,(a6) # stone value
    lw t1,4(a6) # num stones with this value
    addi a6,a6,node_sz # move from ptr for next loop
    bnez t0,d11p1_try_split # not zero, try next rule
    li t0,1 # stone is engraved with 0
    sw t0,(a5) # replace with engraved 1
    sw t1,4(a5) # doesn't change the count
    addi s7,s7,1 # increment to count by 1
    addi a5,a5,node_sz # increment to pointer by 1 (* sizeof)
    j d11p1_expand_stones
d11p1_try_split:
    mv t5,t0 # save these off
    mv t6,t1 # temporarily
    mv a0,t0 # to call count_digits
    call count_digits
    andi t2,a0,0x1 # check if even
    mv t0,t5 # restore
    mv t1,t6 # the values
    bnez t0,d11p1_mul # not 0, so odd
    slli a0,a0,1 # half digits on each side but then *sizeof(u32)
    la a1,tens_array
    add a1,a1,a0
    lw a1,(a1)
    div t2,t0,a1 # value / ten muls == left side
    rem t3,t0,a1 # value % ten muls == right side
    sw t2,(a5) # store the left value
    sw t1,4(a5) # same count as before
    sw t3,8(a5) # store the right value
    sw t1,12(a5) # same count, basically doubled our stones
    addi a5,a5,2*node_sz
    addi s7,s7,2 # added 2 elements to to array
    j d11p1_expand_stones

d11p1_mul:
    li t2,2024 # otherwise mul 2024
    mul t0,t0,t2
    sw t0,(a5) # store the new value
    sw t1,4(a5) # count doesn't change
    addi s7,s7,1 # incr to count by 1
    addi a5,a5,node_sz # incr to ptr by 1 (* sizeof)
    j d11p1_expand_stones

d11p1_expanded:
    mv t0,s4 # swap the arrays
    mv s4,s6 # so to becomes from etc.
    mv s5,s7
    mv s6,t0
    li s7,0
    j d11p1_simulate_iter

d11p1_count_stones:
    mv t0,s7 # last array we wrote to count
    mv a0,s6 # last array
d11p1_count_stones_loop:
    beqz t0,d11p1_done
    lw t1,4(a0) # stone count only
    add s0,s0,t1 # add count to result
    addi a0,a0,8 # increment ptr
    addi t0,t0,-1
    j d11p1_count_stones_loop
d11p1_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

day11_part2:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr


d11p2_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

day11_die:
    call unreachable

# a0 - value
# a1 - cap
hash:

    .data # any useful globals (r/w)
tens_array: # for now lets hope it fits in i32
.word 1 # otherwise we'll need to make these dwords
.word 10
.word 100
.word 1000
.word 10000
.word 100000
.word 1000000
.word 10000000
.word 100000000
.word 1000000000
tens_array_end: .word 0