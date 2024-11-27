    .global day3_part1,day3_part2,printf

    .equ    DOT, 46
    .equ    NEWLINE, 10
    .equ    ZERO, 48
    .equ    COLON, 58                    # because COLON is one after '9'

    .text
day3_part1:
    beqz    a1,d3p1_done_early
    addi    sp,sp,-32                    # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)

    li      s0,0                         # store result in s0
    add     a7,a0,a1                     # a7 == end
    li      t5,0                         # make t5 the "width"
    mv      a6,a0                        # iterate input to find newline
    mv      s1,a0                        # store the beginning of the input
d3p1_find_width:
    lb      t0,(a6)                      # t0 = a6[0]
    addi    t0,t0,-NEWLINE               # t0 -= '/n'
    beqz    t0,d3p1_found_width
    addi    a6,a6,1
    j       d3p1_find_width
d3p1_found_width:
    sub     t5,a6,a0                     # t5 (width) = a6 - a0
    addi    t5,t5,1                      # t5 += 1 to include the newline in the width
    mv      a6,a0                        # use a6 for iterating so we can check if previous neighbor >= s1
    j       d3p1_grid_loop
d3p1_grid_loop_iter:
    addi    a6,a6,1
d3p1_grid_loop:
    beq     a6,a7,d3p1_done              # if input == end break
    lb      a0,(a6)                      # a3 = input[0]
    mv      a1,a0                        # save off so we can check digit
    call    is_digit                     # is '0' <= a0 <= '9'
    beqz    a0,d3p1_grid_loop_iter       # if not keep searching
    li      s3,0                         # s3 is whether this is next to a symbol
    li      a5,0                         # store the current part number
d3p1_check_up_left:
    sub     a0,a6,t5                     # check diagonal-left neighbor
    addi    a0,a0,-1                     # a0 = input - width - 1
    blt     a0,s1,d3p1_check_left
    lb      a0,(a0)
    call    is_symbol
    or      s3,s3,a0                     # near_symbol |= neighbor_is_symbol
d3p1_check_left:
    addi    a0,a6,-1
    blt     a0,s1,d3p1_check_bottom_left
    lb      a0,(a0)
    call    is_symbol
    or      s3,s3,a0
d3p1_check_bottom_left:
    add     a0,a6,t5
    addi    a0,a0,-1
    bge     a0,a7,d3p1_parse_part
    lb      a0,(a0)
    call    is_symbol
    or      s3,s3,a0
d3p1_parse_part: # until not a digit
d3p1_check_up:
    sub     a0,a6,t5                     # check upper neighbor
    blt     a0,s1,d3p1_check_down        # skip check if out of grid
    lb      a0,(a0)                      # a0 = *input
    call    is_symbol
    or      s3,s3,a0
d3p1_check_down:
    add     a0,a6,t5
    bge     a0,a7,d3p1_digit
    lb      a0,(a0)
    call    is_symbol
    or      s3,s3,a0
d3p1_digit:
    lb      a0,(a6)                      # a0 = *input
    mv      a1,a0
    call    is_digit                     # is *input a digit?
    beqz    a0,d3p1_check_if_symbol      # if not see if it's a symbol
    li      t4,10
    addi    a0,a1,-ZERO                  # x = *input - '0'
    mul     a5,a5,t4                     # part_number = part_number * 10
    add     a5,a5,a0                     # part_number += x
    addi    a6,a6,1
    j       d3p1_parse_part
d3p1_check_if_symbol: # if we hit this the parsing is over
    mv      a0,a1
    call    is_symbol
    or      s3,s3,a0
    beqz    s3,d3p1_grid_loop_iter       #not a part, keep searching
    add     s0,s0,a5                     # is a part, add to the total
    j       d3p1_grid_loop_iter

d3p1_done:
    la      a0,d3p1_fmt
    mv      a1,s0
    call    printf

    lw      ra,0(sp)                     # epilogue
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    addi    sp,sp,32
d3p1_done_early:
    ret



    .equ GEAR, '*'

# Similar to 1 except
# we will look for * and then
# figure out what numbers are around us
# a bit more complicated logic when we hit a *
# _but_ it means we don't have to track any state
day3_part2:
    beqz    a1,d3p2_done_early # if input_len == 0 return
    addi    sp,sp,-32                    # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)
    sw      s4,20(sp)
    sw      s5,24(sp)

    li s0,0 # no need for fp, lets use this for return value
    mv s1,a0 # pointer we will use for incrementing/testing so it saves across function calls
    add s2,a0,a1 # save end pointer into s2
    mv s3,a0 # keep an initial pointer for bounds checking
    li s4,0 # we'll use s4 here for the grid width
    li s5,GEAR # store this value here for comparison
    li t1,NEWLINE
d3p2_find_width:
    lb      t0,(a0)                      # t0 = a0[0]
    beq     t0,t1,d3p2_found_width # t0 == '/n' we're done
    addi    a0,a0,1
    j       d3p2_find_width
d3p2_found_width:
    sub s4,a0,s1 # s4 = current_ptr - input_start_ptr
    addi s4,s4,1 # include the newline char
    j d3p2_gear_search
d3p2_gear_search_incr:
    addi s1,s1,1 # input += 1
d3p2_gear_search:
    beq s1,s2,d3p2_done
    lb t0,(s1) # t0 = input[0]
    beq t0,s5,d3p2_found_gear # if input[0] == '*' do gear stuff
    j d3p2_gear_search_incr


d3p2_found_gear: # *s1 == '*'
    li a7,0 # number of number neighbors
    li a6,0 # bitmask for neighbors
d3p2_fg_check_left:
    addi a0,s1,-1
    blt a0,s3,d3p2_fg_check_right
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    or a6,a6,a0
d3p2_fg_check_right:
    addi a0,s1,1
    bge a0,s2,d3p2_fg_check_up
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    slli a0,a0,1
    or a6,a6,a0
d3p2_fg_check_up: # if there is a digit here then there is only 1 number above us
    sub a0,s1,s4
    blt a0,s3,d3p2_fg_check_down
    lb a0,(a0)
    call is_digit
    add a7,a7,a0 # increment number of neighbors if it is
    seqz t5,a0 # if 0 then we need to check top left and top right
    slli a0,a0,2
    or a6,a6,a0
d3p2_fg_check_down:
    add a0,s1,s4
    bge a0,s2,d3p2_fg_check_top_left
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    seqz t4,a0 # if 0 then we need to check bottom left and bottom right
    slli a0,a0,3
    or a6,a6,a0
d3p2_fg_check_top_left:
    beqz t5,d3p2_fg_check_bottom_left # only check top left/right if t5 is set
    sub a0,s1,s4
    addi a0,a0,-1
    blt a0,s3,d3p2_fg_check_top_right
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    slli a0,a0,4
    or a6,a6,a0
d3p2_fg_check_top_right:
    sub a0,s1,s4
    addi a0,a0,1
    blt a0,s3,d3p2_fg_check_bottom_left
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    slli a0,a0,5
    or a6,a6,a0
d3p2_fg_check_bottom_left:
    beqz t4,d3p2_fg_done # only check bottom left/right if t4 is set
    add a0,s1,s4
    addi a0,a0,-1
    bge a0,s2,d3p2_fg_done # if bottom left is > end then bottom right will be
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    slli a0,a0,6
    or a6,a6,a0
d3p2_fg_check_bottom_right:
    add a0,s1,s4
    addi a0,a0,1
    bge a0,s2,d3p2_fg_done
    lb a0,(a0)
    call is_digit
    add a7,a7,a0
    slli a0,a0,7
    or a6,a6,a0
d3p2_fg_done:
    li t3,2
    bne a7,t3,d3p2_gear_search_incr # only a gear ratio if there are exactly 2 numbers
    # now we actually have to calc which neighbor

d3p2_calc_gear_ratio:
    # a6 contains bitmask of what directions we care about
    li a7,1 # gear ratio
d3p2_cgr_left:
    andi a5,a6,1 # left?
    beqz a5,d3p2_cgr_right
    mv a0,s1
    addi a0,a0,-1
    mv a1,s3 # beginning of input
    mv a2,s2 # end of input
    call find_num_range # number range is [a0, a1)
    call parse_int # a0 now contains the value
    mul a7,a7,a0 # multiply gear ratio
d3p2_cgr_right:
    andi a5,a6,2
    beqz a5,d3p2_cgr_up
    mv a0,s1
    addi a0,a0,1
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_up:
    andi a5,a6,4
    beqz a5,d3p2_cgr_down
    mv a0,s1
    sub a0,a0,s4
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_down:
    andi a5,a6,8
    beqz a5,d3p2_cgr_top_left
    mv a0,s1
    add a0,a0,s4
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_top_left:
    andi a5,a6,16
    beqz a5,d3p2_cgr_top_right
    mv a0,s1
    sub a0,a0,s4
    addi a0,a0,-1
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_top_right:
    andi a5,a6,32
    beqz a5,d3p2_cgr_bottom_left
    mv a0,s1
    sub a0,a0,s4
    addi a0,a0,1
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_bottom_left:
    andi a5,a6,64
    beqz a5,d3p2_cgr_bottom_right
    mv a0,s1
    add a0,a0,s4
    addi a0,a0,-1
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_bottom_right:
    andi a5,a6,128
    beqz a5,d3p2_cgr_done
    mv a0,s1
    add a0,a0,s4
    addi a0,a0,1
    mv a1,s3
    mv a2,s2
    call find_num_range
    call parse_int
    mul a7,a7,a0
d3p2_cgr_done:
    add s0,s0,a7
    li a7,0
    j d3p2_gear_search_incr

d3p2_done:
    la a0,d3p2_fmt
    mv a1,s0
    call printf

    lw      ra,0(sp)                     # epilogue
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    lw      s4,20(sp)
    lw      s5,24(sp)
    addi    sp,sp,32
d3p2_done_early:
    ret


# going to cheat here and say
# it is a symbol if it is not a digit
# and not '.' or '/n'
# also cheating because we'll save ra
# into a4 which is...bad
is_symbol:
    mv      t3,a0
    mv      a4,ra
    call    is_digit
    mv      ra,a4
    bnez    a0,is_symbol_false
    addi    t3,t3,-DOT                   # x = *input - '.'
    beqz    t3,is_symbol_false           # it's a '.' so not a symbol
    addi    t3,t3,DOT                    # restore char
    addi    t3,t3,-NEWLINE
    beqz    t3,is_symbol_false           # a newline is also not a symbol
    li      a0,1                         # otherwise it's true
    ret
is_symbol_false:
    li      a0,0
    ret


# a0 - starting position, should be a digit
# a1 - beginning bounds
# a2 - end bounds
# returns:
# a0 - beginning of range
# a1 - end of range
find_num_range:
    mv t3,a1 # t3 = begin bound
    mv t4,a2 # t4 = end bound
    mv a1,a0 # save off a0 to search other direction
fnb_search_beginning: # search left for beginning of number
    addi    a0,a0,-1 # ptr -= 1
    blt     a0,t3,fnb_search_beginning_done # check if we're out of bounds
    lb       t2,(a0) # t2 = *ptr
    slti     t0,t2,ZERO # is_digit but inlined
    xori     t0,t0,1
    slti     t1,t2,COLON
    and      t0,t0,t1 # end of is_digit
    bnez t0,fnb_search_beginning # keep searching while is_digit(*input)
fnb_search_beginning_done: # search right for end of number
    addi a0,a0,1
fnb_search_ending: # basically the same as above but with a1 to find end
    addi a1,a1,1
    bge a1,t4,fnb_search_done
    lb       t2,(a1)
    slti     t0,t2,ZERO
    xori     t0,t0,1
    slti     t1,t2,COLON
    and      t0,t0,t1
    bnez t0,fnb_search_ending
fnb_search_done:
    ret

# takes a string range designated by
# a0 - start of range (includsive) and
# a1 - end of range (exclusive)
# pre: a0 points to a digit
parse_int:
    li t1,10
    mv t2,a0
    mv t3,a1
    li a0,0
    li a1,0
    j parse_int_loop
parse_int_loop_iter:
    addi t2,t2,1
parse_int_loop:
    beq t2,t3,parse_int_done
    lb a1,(t2)
    addi a1,a1,-ZERO
    mul a0,a0,t1
    add a0,a0,a1
    j parse_int_loop_iter
parse_int_done:
    ret

    .data
d3p1_fmt: .string "Part1: %d\n"
d3p2_fmt: .string "Part2: %d\n"
