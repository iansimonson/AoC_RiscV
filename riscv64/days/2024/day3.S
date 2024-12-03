    .global day3_part1,day3_part2,printf,part1_fmt,is_digit,parse_int

    .text
# So some string parsing again
# we'll do kinda state machiney
# with the procs?
# min valid size is mul(1,1) so that's
# 8 characters. max valid size is
# mul(111,111) or 12 characters
# a0 - input
# a1 - length
day3_part1:
    addi    t0,a1,-8                                                  # min character size
    bltz    t0,d3p1_done_early
    addi    sp,sp,-64                                                 # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)
    sd      s4,40(sp)
    sd      s5,48(sp)

    li      s0,0                                                      # result
    mv      s1,a0                                                     # input ptr
    add     s2,a0,t0                                                  # end (length - 8 b/c not possible to parse after that)
    add      s3,a0,a1                                                     # actual end of input for later check
    j       d3p1_search_mul

# we only increment after confirming something is the value (other than m)
# because we might have e.g. mmmul(1,1) which is valid
d3p1_search_mul:
    bge     s1,s2,d3p1_done
    li      t0,'m'
    lb      a1,(s1)                                                   # a1 = *input
    addi    s1,s1,1                                                   # input += 1
    bne     a1,t0,d3p1_search_mul                                     # not an 'm'
    li      t0,'u'                                                    # check *input == u
    lb      a1,(s1)
    bne     a1,t0,d3p1_search_mul
    addi    s1,s1,1
    li      t0,'l'                                                    # check *input == l
    lb      a1,(s1)
    bne     a1,t0,d3p1_search_mul
    addi    s1,s1,1
    li      t0,'('                                                    # check if next is '('
    lb      a1,(s1)
    bne     a1,t0,d3p1_search_mul
    addi    s1,s1,1
    lb      a0,(s1)
    call    is_digit                                                  # are we on a digit?
    beqz    a0,d3p1_search_mul
    mv      a0,s1
    call    parse_int
    mv      s1,a1                                                     # last char after int
    slti    t0,a0,1000                                                # has to be 1-3 chars
    beqz    t0,d3p1_search_mul
    mv      a6,a0                                                     # a6 will be the result from this parsing
    li      t0,','
    bge     s1,s3,d3p1_done                                           # of course from here we might be beyond input
    lb      a1,(s1)
    bne     a1,t0,d3p1_search_mul
    addi    s1,s1,1
    beq     s1,s3,d3p1_done
    lb      a0,(s1)
    call    is_digit                                                  # check for second number
    beqz    a0,d3p1_search_mul
    mv      a0,s1
    call    parse_int                                                 # parse second number
    mv      s1,a1                                                     # update pointer after int
    bge     s1,s3,d3p1_done                                           # if we're beyond the actual end of input there's no ')'
    slti    t0,a0,1000                                                # check second number is 3 chars or less
    beqz    t0,d3p1_search_mul                                        # invalid
    mul     a6,a6,a0                                                  # multiply the two numbers
    li      t0,')'                                                    # confirm the mult ends
    lb      a0,(s1)
    bne     a0,t0,d3p1_search_mul
    add     s0,s0,a6                                                  # success! add the result in
    add     s1,s1,1                                                   # and increment the pointer
    j       d3p1_search_mul

d3p1_done:
    la      a0,part1_fmt
    mv      a1,s0
    call    printf

    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    ld      s4,40(sp)
    ld      s5,48(sp)
    addi    sp,sp,64                                                  # epilogue
d3p1_done_early:
    ret

# the best way to do this would be
# to have made this a state machine
# and just add in do/don't...but we don't
# have that so...if we hit a d, we'll call
# a function parse enable/disable which
# will return "parsed" and "value"
day3_part2:
    addi    t0,a1,-8                                                  # min character size
    bltz    t0,d3p1_done_early
    addi    sp,sp,-64                                                 # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)
    sd      s4,40(sp)
    sd      s5,48(sp)

    li      s0,0                                                      # result
    mv      s1,a0                                                     # input ptr
    add     s2,a0,t0                                                  # end (length - 8 b/c not possible to parse after that)
    add      s3,a0,a1                                                     # actual end of input for later check
    li a7,1 # mults are enabled by default
    j       d3p2_search_mul

# we only increment after confirming something is the value (other than m)
# because we might have e.g. mmmul(1,1) which is valid
d3p2_search_mul:
    bge     s1,s2,d3p2_done
    li t0,'d'
    lb a1,(s1)
    bne a1,t0,d3p2_try_parse_mul
    addi s1,s1,1 # ok because this _was_ a 'd'
    mv a0,s1 # setup for call parse_do_dont
    call parse_do_dont
    beqz a0,d3p2_search_mul # if wasn't a do or don't then continue parsing from s1
    mv s1,a2 # update pointer if we did parse a do/don't so we don't reparse
    mv a7,a1 # we parsed a do/don't so we are now are enabled/disabled
    j d3p2_search_mul
d3p2_try_parse_mul:
    bnez    a7,d3p2_enabled_parse # if muls are disabled, no point in parsing until we enable again
    addi s1,s1,1 # it wasn't a 'd' because we're here but we're disabled so just skip
    j d3p2_search_mul
d3p2_enabled_parse:
    li      t0,'m'
    lb      a1,(s1)                                                   # a1 = *input
    addi    s1,s1,1                                                   # input += 1
    bne     a1,t0,d3p2_search_mul                                     # not an 'm'
    li      t0,'u'                                                    # check *input == u
    lb      a1,(s1)
    bne     a1,t0,d3p2_search_mul
    addi    s1,s1,1
    li      t0,'l'                                                    # check *input == l
    lb      a1,(s1)
    bne     a1,t0,d3p2_search_mul
    addi    s1,s1,1
    li      t0,'('                                                    # check if next is '('
    lb      a1,(s1)
    bne     a1,t0,d3p2_search_mul
    addi    s1,s1,1
    lb      a0,(s1)
    call    is_digit                                                  # are we on a digit?
    beqz    a0,d3p2_search_mul
    mv      a0,s1
    call    parse_int
    mv      s1,a1                                                     # last char after int
    slti    t0,a0,1000                                                # has to be 1-3 chars
    beqz    t0,d3p2_search_mul
    mv      a6,a0                                                     # a6 will be the result from this parsing
    li      t0,','
    bge     s1,s3,d3p2_done                                           # of course from here we might be beyond input
    lb      a1,(s1)
    bne     a1,t0,d3p2_search_mul
    addi    s1,s1,1
    beq     s1,s3,d3p2_done
    lb      a0,(s1)
    call    is_digit                                                  # check for second number
    beqz    a0,d3p2_search_mul
    mv      a0,s1
    call    parse_int                                                 # parse second number
    mv      s1,a1                                                     # update pointer after int
    bge     s1,s3,d3p2_done                                           # if we're beyond the actual end of input there's no ')'
    slti    t0,a0,1000                                                # check second number is 3 chars or less
    beqz    t0,d3p2_search_mul                                        # invalid
    mul     a6,a6,a0                                                  # multiply the two numbers
    li      t0,')'                                                    # confirm the mult ends
    lb      a0,(s1)
    bne     a0,t0,d3p2_search_mul
    add     s0,s0,a6                                                  # success! add the result in
    add     s1,s1,1                                                   # and increment the pointer
    j       d3p2_search_mul

d3p2_done:
    la      a0,part1_fmt
    mv      a1,s0
    call    printf

    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    ld      s4,40(sp)
    ld      s5,48(sp)
    addi    sp,sp,64                                                  # epilogue
d3p2_done_early:
    ret

# parse do or don't, first letter _should_ be an 'o'
# because we already parsed a 'd' to call this
# undefined if the end of input is a d and we run off end
# of string "yay"
# a0 - start of parsing (letter after 'd')
# returns:
# a0 - parsed/did not parse
# a1 - enabled/disabled
# a2 - end of input we parsed to skip ahead
parse_do_dont:
    li t0,'o'
    lb t1,(a0)
    bne t1,t0,parse_dd_fail
    addi a0,a0,1 # next input, we have parsed "do" now
    mv a2,a0 # character after "do" even if we don't parse "don't"
    li t0,'n'
    lb t1,(a0)
    bne t1,t0,parse_dd_enable # when this fails, we're enabled
    addi a0,a0,1
    li t0,39 # ' in ascii
    lb t1,(a0)
    bne t1,t0,parse_dd_enable
    addi a0,a0,1
    li t0,'t'
    lb t1,(a0)
    bne t1,t0,parse_dd_enable
    addi a2,a0,1 # we parsed "don't"! put char after t into a2
parse_dd_disable:
    li a0,1 # successfully parsed (use a1 and a2)
    li a1,0 # parsed disable
    ret
parse_dd_enable:
    li a0,1 # successfully parsed (use a1 and a2)
    li a1,1 # parsed enable
    ret # a2 set up by parsing
parse_dd_fail:
    li a0,0 # didn't even parse an 'o' just return
    ret