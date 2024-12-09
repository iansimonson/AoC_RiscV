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
    mv           s3,a0                                       # save off the number we're looking for (lower)
    mv           s4,a1                                       # higher bits
    mv           s1,a2                                       # update our input ptr
    
    mv           a0,s1
    li           a1,COLON
    addi         s1,s1,1                                     # update input ptr
    call         ensure_character                            # dies if not char
    mv           a0,s1
    li           a1,SPACE
    addi         s1,s1,1
    call         ensure_character

    mv           s5,sp                                       # s5 will be our array of ints
    mv           a0,s1
    mv           a1,s5
    call         parse_list_int
    beqz         a2,day7_die                                 # no ints parsed, that shouldn't be possible
    mv           s6,a2                                       # s6: s6 is basically a slice of ints
    mv           s1,a0                                       # s1 ready for next loop

    mv           a0,s3                                       # number we're looking for
    mv           a1,s4                                       # number upper bits
    lw           a2,0(s5)                                    # first number we're starting with
    li           a3,0 # always starting with zeroes in the upper bits
    addi         a4,s5,4                                     # start with the second parsed integer
    addi         a5,s6,-1                                    # size of rest of array
    la           a6,ops                                      # the ops global array
    li           a7,2                                        # just add and mul
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

# I think 30 i8s is probably enough
# but I made my parse_list_int parse i32s
# so we'll do it like that
    addi         sp,sp,-120                                  # 30 * 4 - 30 i32s

d7p2_outer_loop:
    beq          s1,s2,d7p2_done                             # out of input, done
    mv           a0,s1
    call         parse_i64                                   # specifying here to make porting easier
    mv           s3,a0                                       # save off the number we're looking for (lower)
    mv           s4,a1                                       # higher bits
    mv           s1,a2                                       # update our input ptr
    
    mv           a0,s1
    li           a1,COLON
    addi         s1,s1,1                                     # update input ptr
    call         ensure_character                            # dies if not char
    mv           a0,s1
    li           a1,SPACE
    addi         s1,s1,1
    call         ensure_character

    mv           s5,sp                                       # s5 will be our array of ints
    mv           a0,s1
    mv           a1,s5
    call         parse_list_int
    beqz         a2,day7_die                                 # no ints parsed, that shouldn't be possible
    mv           s6,a2                                       # s6: s6 is basically a slice of ints
    mv           s1,a0                                       # s1 ready for next loop

    mv           a0,s3                                       # number we're looking for
    mv           a1,s4                                       # number upper bits
    lw           a2,0(s5)                                    # first number we're starting with
    li           a3,0 # always starting with zeroes in the upper bits
    addi         a4,s5,4                                     # start with the second parsed integer
    addi         a5,s6,-1                                    # size of rest of array
    la           a6,ops                                      # the ops global array
    li           a7,2                                        # just add and mul
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

# a0, a1 - lhs (lower and higher)
# a2 - rhs (lower only)
# returns a0, a1 - 64 bit value of add
d7_add:
    addu         t0,a0,a2
    sltu         t1,t0,a0 # carry if less than
    mv a0,t0 # set a0 now
    add a1,t1 # add carry if necessary
    ret
d7_mul:
    mulhu          t0,a0,a2
    mulu           a0,a0,a2
    mulu           a1,a2
    add            a1,a1,t0 # add carry from lower bits mult
    ret
# requires non-zero values
# for a0 a1 a2
d7_concat:
    mv           t0,a2
    li           t1,10
d7_concat_loop:
    beqz         t0,d7_concat_loop_done
    mulhu         t3,a0,t1
    mulu          t2,a0,t1
    mv a0,t2
    mulu a1,t1
    add a1,a1,t3
    div          t0,t0,t1
    j            d7_concat_loop
d7_concat_loop_done:
    add          t0,a0,a2
    sltu t1,t0,a0 # overflow
    mv a0,t0
    add a1,a1,t1 # add the overflow
    ret

# a0 - number to make lower
# a1 - number to make higher
# a2 - starting value lower
# a3 - starting value higher
# a4 - pointer to integers (32-bit)
# a5 - length of integer list
# a6 - pointer to ops to use
# a7 - length of ops array
d7_can_make_number:
    # I did this on r64 first which is why the offsets aren't back to back
    # but it's _FINE_
    addi         sp,sp,-80                                   # for saving off registers
    sw           ra,72(sp)                                   # save RA register
    sw           s0,0(sp)                                    # value we need
    sw           s1,8(sp)                                    # value we have
    sw           s2,16(sp)                                   # next value we can use
    sw           s3,24(sp)                                   # rest of slice
    sw           s4,32(sp)                                   # remaining num count
    sw           s5,40(sp)                                   # ops
    sw           s6,48(sp)                                   # num ops

    bne          a0,a2,d7_can_make_not_same_value # check both lower and upper
    bne          a1,a3,d7_can_make_not_same_value # registers to see if it's the same value
    j d7_can_make_same_value # low and high the same so goto same value

d7_can_make_not_same_value:
    beqz         a5,d7_can_make_no                           # no more values and not same value. done
    bgt          a3,a1,d7_can_make_no                        # upper bits are larger than upper bits

d7_can_make_check_remaining:
# we can start recursing here
    lw           t0,(a4)
    addi         a4,a4,4
    addi         a5,a5,-1                                    # next recursion has one less integer

# easier for me to think in s registers intead of sp offsets
    mv           s0,a0
    mv           s1,a1
    mv           s2,t0
    mv           s3,a2
    mv           s4,a3
    mv           s5,a4                                       # current ops left
    mv           s6,a5                                       # current ops remaining
    mv           s7,a6
    mv           s8,a7
    sw           s7,56(sp)                                   # store for recursive calls
    sw           s8,64(sp)                                   # store for recursive calls

d7_can_make_loop:
    beqz         s8,d7_can_make_no                           # out of ops, done
    mv           a0,s3                                       # value we have
    mv           a1,s4
    mv           a2,s2                                       # next value we can use
    ld           t0,(s7)                                     # load ops_add _value_ which is d7_add addr into t0
    jalr         ra,t0                                       # jump to the next op
# a0 is now the next number using that op
    mv           a2,a0                                       # move that into a1 for recursion
    mv           a3,a1
    mv           a0,s0                                       # the number we need
    mv           a1,s1
    mv           a4,s5                                       # remaining ints
    mv           a5,s6                                       # remaining ints len
    ld           a6,56(sp)                                   # the full ops list
    ld           a7,64(sp)                                   # full ops list len
    call         d7_can_make_number                          # recursive call
    bnez         a0,d7_can_make_yes                          # true (1) so we're good!
    addi         s7,s5,4                                     # increment ops array
    addi         s8,s6,-1                                    # decrement remaining ops
    j            d7_can_make_loop

d7_can_make_same_value:
    beqz         a5,d7_can_make_yes                          # list is empty and a0 == a1, success!
    j            d7_can_make_check_remaining                 # might be all 1s we can multiply
d7_can_make_no:
    li           a0,0
    j            d7_can_make_done
d7_can_make_yes:
    li           a0,1
    j            d7_can_make_done
d7_can_make_done:
# restore all the s registers and ra
    lw           ra,72(sp)
    lw           s0,0(sp)                                    # value we need
    lw           s1,8(sp)                                    # value we have
    lw           s2,16(sp)                                   # next value we can use
    lw           s3,24(sp)                                   # rest of slice
    lw           s4,32(sp)                                   # remaining num count
    lw           s5,40(sp)                                   # ops
    lw           s6,48(sp)                                   # num ops
    addi         sp,sp,80
    ret

    .data                                                    # any useful globals (r/w)
ops:
ops_add:
    .word       d7_add
ops_mul:
    .word       d7_mul
ops_concat:
    .word       d7_concat
ops_end:
    .word       0
d7p1_fmt:
    .string      "Part1: %u\n"
d7p2_fmt:
    .string      "Part2: %u\n"
d7p1_debug_fmt:
    .string      "MATCHED: %u\n"
