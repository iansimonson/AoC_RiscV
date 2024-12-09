#include "macros.S"
    .global      day8_part1,day8_part2                      # this file
    .global      printf,malloc,memset                       # libc
    .global      is_digit,string_eq,parse_int_range         # begin utility.S
    .global      parse_int,sort_int,part1_fmt,part2_fmt
    .global      grid_load_neighbor_offsets,grid_find_width
    .global      unreachable                                # end utility.S

    .equ         NEWLINE, '\n'
    .equ         DOT, '.'

    .text

# iterate through the input
# and count the number of times each
# frequency appears. Also store the (x,y)
# of each node
# the total number of antinodes is sum(2 * choose(n, 2), each freq)
# but since we have to figure out what goes out of bounds
# we have to store and then calculate each antinode position anyway
# Based on example distance can be manhattan distance
# so we basically just have to take each pair, find distance (node2 - node1)
# and then do (node1 - distance) and (node2 + distance) and yay
day8_part1:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr
    mv           s7,s1                                      # store begin pointer for calculating index

    mv           a0,s1
    call         grid_find_width
    mv           s3,a0                                      # save width in s3
    addi         s4,a0,-1                                   # max X value is 1 less than width

    la           a0,ascii_map                               # this map is where we'll store the count
    li           a1, 0                                      # by map I mean an array of 256 values
    li           a2, 256                                    # will double as our small array length into
    call         memset                                     # the malloc'd array below

    li           a0,5120                                    # (x,y) for each ascii value, max 10 per
    call         malloc
    beqz         a0,day8_die                                # nothing we can do then
    mv           s5,a0                                      # coord map
    la           s6,ascii_map

    sub          a0,s2,s1                                   # we need a visited map dammit
    call         malloc
    beqz         a0,day8_die
    mv           s8,a0                                      # i hate we have to do this
    sub          a2,s2,s1                                   # size
    li           a1,0                                       # clear
    call         memset

    li           t4,NEWLINE
    li           t5,DOT
    li           a7,20                                      # bytes per frequency entry in coord map (10 * (x, y))
    j            d8p1_count_values
d8p1_count_values_incr:
    addi         s1,s1,1
d8p1_count_values:
    beq          s1,s2,d8p1_antinodes
    lb           t0,(s1)
    beq          t0,t4,d8p1_count_values_incr               # NEWLINE, continue
    beq          t0,t5,d8p1_count_values_incr               # DOT, skip

    mul          a1,t0,a7                                   # go from offset into ascii map -> offset into coord map

    add          t1,s6,t0                                   # offset into ascii map
    lb           t2,(t1)                                    # load the current value t2 = ascii_map[char]
    slli         t3,t2,1                                    # 2 bytes per element
    add          a1,a1,t3                                   # next position in coord map to write coords

# ascii_map[char] += 1
    addi         t2,t2,1                                    # increment
    sb           t2,(t1)                                    # store back new value

    add          t1,s5,a1                                   # coord offset to write
    sub          t0,s1,s7                                   # index into input
# in riscv if you do a div followed by a rem immeidately
# with the same source registers
# this becomes 1 actual instruction in hardware
    div          t2,t0,s3                                   # y coord
    rem          t3,t0,s3                                   # x coord
    sb           t3,(t1)                                    # store x
    sb           t2,1(t1)                                   # store y
    j            d8p1_count_values_incr

d8p1_antinodes:
    li           a0,0                                       # luckily registers are not u8s
    li           a1,256                                     # end index
    li           s0,0
d8p1_antinodes_outerloop_incr: # ok to start with a+1 b/c ascii_map[0] is count of null terminators (0)
    add          a0,a0,1
d8p1_antinodes_outerloop:
    beq          a0,a1,d8p1_done
    add          a2,s6,a0                                   # offset into ascii_map
    lb           t0,(a2)                                    # get count at *ptr
    beqz         t0,d8p1_antinodes_outerloop_incr           # count is 0, continue
    mul          a3,a0,a7                                   # ascii offset -> 10 * (x,y) offset
    slli         t1,t0,1                                    # 2 elements per
    add          a4,a3,t1                                   # a4 is now the "end" of the small array offset
    add          a3,s5,a3                                   # a3 is now pointer to small array in coord map for this character
    add          a4,s5,a4                                   # a4 is now the pointer to the end of the small array
    j            d8p1_antinode_inner_loop
d8p1_antinode_inner_loop_incr:
    addi         a3,a3,2                                    # 2 bytes per element
d8p1_antinode_inner_loop:
    beq          a3,a4,d8p1_antinodes_outerloop_incr        # no more pairs, continue
    lb           t0,(a3)                                    # x coord
    lb           t1,1(a3)                                   # y coord
    addi         t2,a3,2                                    # inner inner loop
    j            d8p1_antinode_pair_loop
d8p1_antinode_pair_loop_incr:
    addi         t2,t2,2                                    # increment inner pair loop
d8p1_antinode_pair_loop:
    beq          t2,a4,d8p1_antinode_inner_loop_incr
    lb           t3,(t2)                                    # x coord
    lb           t4,1(t2)                                   # y coord
    sub          t5,t3,t0                                   # x distance
    sub          t6,t4,t1                                   # y distance
    sub          a5,t0,t5                                   # node1_x - d_x
    sub          a6,t1,t6                                   # node1_y - d_y
    bltz         a5,d8p1_antinode_pair_check_other          # assume square grid
    bge          a5,s4,d8p1_antinode_pair_check_other
    bltz         a6,d8p1_antinode_pair_check_other
    bge          a6,s4,d8p1_antinode_pair_check_other
# great it's in the grid, now does it overlap another antinode
# need to check *(s8 + (a6 * s3 + a5)) == 0
    mul          a6,a6,s3
    add          a6,a6,a5                                   # offset
    add          a6,s8,a6                                   # pointer to visited
    lb           a5,(a6)
    bnez         a5,d8p1_antinode_pair_check_other
    addi         s0,s0,1                                    # one more antinode
    li           a5,1
    sb           a5,(a6)
d8p1_antinode_pair_check_other:
    add          a5,t3,t5                                   # node2_x + d_x
    add          a6,t4,t6                                   # node2_y + d_y
    bltz         a5,d8p1_antinode_pair_loop_incr            # assume square grid
    bge          a5,s4,d8p1_antinode_pair_loop_incr
    bltz         a6,d8p1_antinode_pair_loop_incr
    bge          a6,s4,d8p1_antinode_pair_loop_incr
    mul          a6,a6,s3
    add          a6,a6,a5                                   # offset
    add          a6,s8,a6                                   # pointer to visited
    lb           a5,(a6)
    bnez         a5,d8p1_antinode_pair_loop_incr
    addi         s0,s0,1                                    # one more antinode
    li           a5,1
    sb           a5,(a6)
    j            d8p1_antinode_pair_loop_incr
d8p1_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    mv           a0,s8
    call         free
    mv           a0,s5
    call         free

    AOC_EPILOGUE
    ret

day8_part2:
    AOC_PROLOGUE

    li           s0,0                                       # result
    mv           s1,a0                                      # input
    add          s2,a0,a1                                   # end ptr
    mv           s7,s1                                      # store begin pointer for calculating index

    mv           a0,s1
    call         grid_find_width
    mv           s3,a0                                      # save width in s3
    addi         s4,a0,-1                                   # max X value is 1 less than width

    la           a0,ascii_map                               # this map is where we'll store the count
    li           a1, 0                                      # by map I mean an array of 256 values
    li           a2, 256                                    # will double as our small array length into
    call         memset                                     # the malloc'd array below

    li           a0,5120                                    # (x,y) for each ascii value, max 10 per
    call         malloc
    beqz         a0,day8_die                                # nothing we can do then
    mv           s5,a0                                      # coord map
    la           s6,ascii_map

    sub          a0,s2,s1                                   # we need a visited map dammit
    call         malloc
    beqz         a0,day8_die
    mv           s8,a0                                      # i hate we have to do this
    sub          a2,s2,s1                                   # size
    li           a1,0                                       # clear
    call         memset

    li           t4,NEWLINE
    li           t5,DOT
    li           a7,20                                      # bytes per frequency entry in coord map (10 * (x, y))
    j            d8p2_count_values
d8p2_count_values_incr:
    addi         s1,s1,1
d8p2_count_values:
    beq          s1,s2,d8p2_antinodes
    lb           t0,(s1)
    beq          t0,t4,d8p2_count_values_incr               # NEWLINE, continue
    beq          t0,t5,d8p2_count_values_incr               # DOT, skip

    mul          a1,t0,a7                                   # go from offset into ascii map -> offset into coord map

    add          t1,s6,t0                                   # offset into ascii map
    lb           t2,(t1)                                    # load the current value t2 = ascii_map[char]
    slli         t3,t2,1                                    # 2 bytes per element
    add          a1,a1,t3                                   # next position in coord map to write coords

# ascii_map[char] += 1
    addi         t2,t2,1                                    # increment
    sb           t2,(t1)                                    # store back new value

    add          t1,s5,a1                                   # coord offset to write
    sub          t0,s1,s7                                   # index into input
# in riscv if you do a div followed by a rem immeidately
# with the same source registers
# this becomes 1 actual instruction in hardware
    div          t2,t0,s3                                   # y coord
    rem          t3,t0,s3                                   # x coord
    sb           t3,(t1)                                    # store x
    sb           t2,1(t1)                                   # store y
    j            d8p2_count_values_incr

d8p2_antinodes:
    li           s9,0
    li           s10,256                                    # end index
    li           s0,0
d8p2_antinodes_outerloop_incr: # ok to start with a+1 b/c ascii_map[0] is count of null terminators (0)
    add          s9,s9,1
d8p2_antinodes_outerloop:
    beq          s9,s10,d8p2_count_bools
    add          a2,s6,s9                                   # offset into ascii_map
    lb           t0,(a2)                                    # get count at *ptr
    beqz         t0,d8p2_antinodes_outerloop_incr           # count is 0, continue
    li           t1,20
    mul          a3,s9,t1                                   # ascii offset -> 10 * (x,y) offset
    slli         t1,t0,1                                    # 2 elements per
    add          a4,a3,t1                                   # a4 is now the "end" of the small array offset
    add          a3,s5,a3                                   # a3 is now pointer to small array in coord map for this character
    add          a4,s5,a4                                   # a4 is now the pointer to the end of the small array
    mv           a0,a3                                      # pointer to coords to check
    mv           a1,a4                                      # pointer to end of coords
    mv           a2,s3                                      # grid width (includes newline)
    mv           a3,s8                                      # visited grid
    call         d8p2_draw_lines
    j            d8p2_antinodes_outerloop_incr

d8p2_count_bools:
    li           s0,0
    mv           a0,s8
    sub          t0,s2,s7                                   # length of visited array
    add          a1,s8,t0                                   # end pointer
d8p2_count_bools_loop:
    beq          a0,a1,d8p2_done
    lb           t0,(a0)
    addi         a0,a0,1
    add          s0,s0,t0                                   # either a 0 or 1
    j            d8p2_count_bools_loop
d8p2_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

    mv           a0,s8
    call         free
    mv           a0,s5
    call         free

    AOC_EPILOGUE
    ret

day8_die:
    call         unreachable


# a0 - ptr to coord array
# a1 - end ptr to coord array
# a2 - grid_width
# a3 - visited grid
d8p2_draw_lines:
    add          sp,sp,-64
    sw           s0,(sp)
    sw           s1,8(sp)
    sw           s2,16(sp)
    sw           s3,24(sp)
    sw           s4,32(sp)
    sw           s5,40(sp)
    sw           s6,48(sp)

    li           s0,0
    mv           s1,a0
    mv           s2,a1
    mv           s3,a2
    mv           s4,a3
    j            d8p2_dl_loop

d8p2_dl_loop_incr:
    addi         s1,s1,2                                    # 2 bytes per element
d8p2_dl_loop:
    beq          s1,s2,d8p2_draw_lines_done                 # no more pairs
    lb           a0,(s1)                                    # x coord
    lb           a1,1(s1)                                   # y coord
    addi         t2,s1,2                                    # inner inner loop
    j            d8p2_antinode_pair_loop
d8p2_antinode_pair_loop_incr:
    addi         t2,t2,2                                    # increment inner pair loop
d8p2_antinode_pair_loop:
    beq          t2,s2,d8p2_dl_loop_incr
    lb           a3,(t2)                                    # x coord
    lb           a4,1(t2)                                   # y coord
    sub          t5,a3,a0                                   # x distance
    sub          t6,a4,a1                                   # y distance

d8p2_antinode_pl_mark_up:
    mv           s5,a0
    mv           s6,a1
d8p2_antinode_pl_mark_up_loop:
    mul          t0,s6,s3                                   # y * width
    add          t0,t0,s5                                   # t0 + x = index into array
    add          t1,s4,t0
    li           a6,1
    sb           a6,(t1)                                    # mark this as visited
    sub          s5,s5,t5                                   # node1_x - d_x
    sub          s6,s6,t6                                   # node1_y - d_y
    addi         a7,s3,-1                                   # remove newline when checking
    bltz         s5,d8p2_antinode_pl_mark_down              # assume square grid
    bge          s5,a7,d8p2_antinode_pl_mark_down
    bltz         s6,d8p2_antinode_pl_mark_down
    bge          s6,a7,d8p2_antinode_pl_mark_down
    j            d8p2_antinode_pl_mark_up_loop

d8p2_antinode_pl_mark_down:
    mv           s5,a3
    mv           s6,a4
d8p2_antinode_pl_mark_down_loop:
    mul          t0,s6,s3                                   # y * width
    add          t0,t0,s5                                   # t0 + x = index into array
    add          t1,s4,t0
    li           a6,1
    sb           a6,(t1)
    add          s5,s5,t5                                   # node2_x + d_x
    add          s6,s6,t6                                   # node2_y + d_y
    addi         a7,s3,-1                                   # remove newline when checking
    bltz         s5,d8p2_antinode_pair_loop_incr            # assume square grid
    bge          s5,a7,d8p2_antinode_pair_loop_incr
    bltz         s6,d8p2_antinode_pair_loop_incr
    bge          s6,a7,d8p2_antinode_pair_loop_incr
    j            d8p2_antinode_pl_mark_down_loop

d8p2_draw_lines_done:
    lw           s0,(sp)
    lw           s1,8(sp)
    lw           s2,16(sp)
    lw           s3,24(sp)
    lw           s4,32(sp)
    lw           s5,40(sp)
    lw           s6,48(sp)
    addi         sp,sp,64
    ret

    .data                                                   # any useful globals (r/w)
ascii_map:
    .space       256, 0                                     # count of each letter found
ascii_map_end:
    .byte        0
