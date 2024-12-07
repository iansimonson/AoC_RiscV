#include "macros.S"
    .global      day7_part1,day7_part2                       # this file
    .global      printf,malloc,memset                        # libc
    .global      is_digit,string_eq,parse_int_range          # begin utility.S
    .global      parse_int,parse_i64,parse_list_int,sort_int
    .global      grid_load_neighbor_offsets,grid_find_width
    .global      unreachable,ensure_character                # end utility.S

    .equ         COLON, ':'
    .equ         SPACE, ' '

    .text
day7_part1:
    AOC_PROLOGUE

    li           s0,0                                        # result
    mv           s1,a0                                       # input
    add          s2,a0,a1                                    # end ptr

# I think 30 i8s is probably enough
# but I made my parse_list_int parse i32s
# so we'll do it like that
    addi         sp,sp,-120                                  # 30 * 4 - 30 i32s

d7p1_outer_loop:
    beq          s1,s2,d7p1_done                             # out of input, done
    mv           a0,s1
    call         parse_i64                                   # specifying here to make porting easier
    mv           s3,a0                                       # save off the number we're looking for
    mv           s1,a1                                       # update our input ptr
    mv           a0,s1
    li           a1,COLON
    addi         s1,s1,1                                     # update input ptr
    call         ensure_character                            # dies if not char
    mv           a0,s1
    li           a1,SPACE
    addi         s1,s1,1
    call         ensure_character

    mv           s4,sp                                       # s4 will be our array of ints
    mv           a0,s1
    mv           a1,s4
    call         parse_list_int
    beqz         a2,day7_die                                 # no ints parsed, that shouldn't be possible
    mv           s5,a2                                       # s4: s5 is basically a slice of ints
    mv           s1,a0                                       # s1 ready for next loop

    mv           a0,s3                                       # number we're looking for
    lw           a1,0(s4)                                    # first number we're starting with
    addi         a2,s4,4                                     # start with the second parsed integer
    addi         a3,s5,-1                                    # size of rest of array
    la           a4,ops                                      # the ops global array
    li           a5,2                                        # just add and mul
    call         d7_can_make_number
    beqz         a0,d7p1_outer_loop
    add          s0,s0,s3
    j            d7p1_outer_loop

d7p1_done:
    la           a0,d7p1_fmt
    mv           a1,s0
    call         printf

    addi         sp,sp,120                                   # free the stack array we made before
    AOC_EPILOGUE
    ret

day7_part2:
    AOC_PROLOGUE

    li           s0,0                                        # result
    mv           s1,a0                                       # input
    add          s2,a0,a1                                    # end ptr

    addi         sp,sp,-120                                  # 30 * 4 - 30 i32s

d7p2_outer_loop:
    beq          s1,s2,d7p2_done                             # out of input, done
    mv           a0,s1
    call         parse_i64                                   # specifying here to make porting easier
    mv           s3,a0                                       # save off the number we're looking for
    mv           s1,a1                                       # update our input ptr
    mv           a0,s1
    li           a1,COLON
    addi         s1,s1,1                                     # update input ptr
    call         ensure_character                            # dies if not char
    mv           a0,s1
    li           a1,SPACE
    addi         s1,s1,1
    call         ensure_character

    mv           s4,sp                                       # s4 will be our array of ints
    mv           a0,s1
    mv           a1,s4
    call         parse_list_int
    beqz         a2,day7_die                                 # no ints parsed, that shouldn't be possible
    mv           s5,a2                                       # s4: s5 is basically a slice of ints
    mv           s1,a0                                       # s1 ready for next loop

    mv           a0,s3                                       # number we're looking for
    lw           a1,0(s4)                                    # first number we're starting with
    addi         a2,s4,4                                     # start with the second parsed integer
    addi         a3,s5,-1                                    # size of rest of array
    la           a4,ops                                      # the ops global array
    li           a5,3                                        # add mul and concat
    call         d7_can_make_number
    beqz         a0,d7p2_outer_loop
    add          s0,s0,s3
    j            d7p2_outer_loop

d7p2_done:
    la           a0,d7p2_fmt
    mv           a1,s0
    call         printf

    addi         sp,sp,120                                   # free the stack array we made before
    AOC_EPILOGUE
    ret

day7_die:
    call         unreachable

# a0, a1 - input
# returns a0 - output of add
d7_add:
    add          a0,a0,a1
    ret
d7_mul:
    mul          a0,a0,a1
    ret
# requires non-zero values
# for a0 a1
d7_concat:
    mv           t0,a1
    li           t1,10
d7_concat_loop:
    beqz         t0,d7_concat_loop_done
    mul          a0,a0,t1
    div          t0,t0,t1
    j            d7_concat_loop
d7_concat_loop_done:
    add          a0,a0,a1
    ret

# a0 - number to make
# a1 - starting value
# a2 - pointer to integers (32-bit)
# a3 - length of integer list
# a4 - pointer to ops to use
# a5 - length of ops array
d7_can_make_number:
# could skip this if we made a "done early" but just be consistent for now
    addi         sp,sp,-80                                   # for saving off registers
    sd           ra,72(sp)                                   # save RA register
    sd           s0,0(sp)                                    # value we need
    sd           s1,8(sp)                                    # value we have
    sd           s2,16(sp)                                   # next value we can use
    sd           s3,24(sp)                                   # rest of slice
    sd           s4,32(sp)                                   # remaining num count
    sd           s5,40(sp)                                   # ops
    sd           s6,48(sp)                                   # num ops

    beq          a0,a1,d7_can_make_same_value
    beqz         a3,d7_can_make_no                           # no more values and not same value. done
    bgt          a1,a0,d7_can_make_no                        # too large so skip

d7_can_make_check_remaining:
# we can start recursing here
    lw           t0,(a2)
    addi         a2,a2,4
    addi         a3,a3,-1                                    # next recursion has one less integer

# easier for me to think in s registers intead of sp offsets
    mv           s0,a0
    mv           s1,a1
    mv           s2,t0
    mv           s3,a2
    mv           s4,a3
    mv           s5,a4                                       # current ops left
    mv           s6,a5                                       # current ops remaining
    sd           s5,56(sp)                                   # store for recursive calls
    sd           s6,64(sp)                                   # store for recursive calls

d7_can_make_loop:
    beqz         s6,d7_can_make_no                           # out of ops, done
    mv           a0,s1                                       # value we have
    mv           a1,s2                                       # next value we can use
    ld           t0,(s5)                                     # load ops_add _value_ which is d7_add addr into t0
    jalr         ra,t0                                       # jump to the next op
# a0 is now the next number using that op
    mv           a1,a0                                       # move that into a1 for recursion
    mv           a0,s0                                       # the number we need
    mv           a2,s3                                       # remaining ints
    mv           a3,s4                                       # remaining ints len
    ld           a4,56(sp)                                   # the full ops list
    ld           a5,64(sp)                                   # full ops list len
    call         d7_can_make_number                          # recursive call
    bnez         a0,d7_can_make_yes                          # true (1) so we're good!
    addi         s5,s5,8                                     # increment ops array
    addi         s6,s6,-1                                    # decrement remaining ops
    j            d7_can_make_loop

d7_can_make_same_value:
    beqz         a3,d7_can_make_yes                          # list is empty and a0 == a1, success!
    j            d7_can_make_check_remaining                 # might be all 1s we can multiply
d7_can_make_no:
    li           a0,0
    j            d7_can_make_done
d7_can_make_yes:
    li           a0,1
    j            d7_can_make_done
d7_can_make_done:
# restore all the s registers and ra
    ld           ra,72(sp)
    ld           s0,0(sp)                                    # value we need
    ld           s1,8(sp)                                    # value we have
    ld           s2,16(sp)                                   # next value we can use
    ld           s3,24(sp)                                   # rest of slice
    ld           s4,32(sp)                                   # remaining num count
    ld           s5,40(sp)                                   # ops
    ld           s6,48(sp)                                   # num ops
    addi         sp,sp,80
    ret

    .data                                                    # any useful globals (r/w)
ops:
ops_add:
    .dword       d7_add
ops_mul:
    .dword       d7_mul
ops_concat:
    .dword       d7_concat
ops_end:
    .dword       0
d7p1_fmt:
    .string      "Part1: %zu\n"
d7p2_fmt:
    .string      "Part2: %zu\n"
d7p1_debug_fmt:
    .string      "MATCHED: %zu\n"
