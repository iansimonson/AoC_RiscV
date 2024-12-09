#include "macros.S"

    .global      day5_part1,day5_part2                             # provided by this file
    .global      printf,malloc,free,memset                         # from libc
    .global      parse_int,unreachable                             # utility.S

    .text
# Every number is a 2 digit number, so we only have max 100,
# really 90 b/c 10-99 so we can just have an array
# make it an array of 30 elements each
# and a second array with the counts
# reverse iterate the lines
# each value, look up what numbers have to come _after_
# and mark them in a bool array (or bit array whatever)
# when a value has already been marked - BAD
# otherwise we're ok, add the middle number
day5_part1:
    AOC_PROLOGUE

# setup and create arrays for tracking rules
# could have made these globals _but_
# on esp32c3 I'm running out of sram and
# malloc can use flash
    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr
    li           a0,3000                                           # 30 elements x 100 values
    call         malloc
    beqz         a0,d5_die
    mv           s3,a0                                             # store the rules array in s3
    li           a1,0
    li           a2,3000
    call         memset                                            # zero the rules array

    li           a0,100                                            # 100 values, num elements in s3 per value
    call         malloc
    beqz         a0,d5_die
    mv           s4,a0                                             # store lengths array in s4
    li           a1,0
    li           a2,100
    call         memset                                            # zero the lengths array

# don't need to memset this one because our parser returns len()
    li           a0,30                                             # over allocate array for updates
    call         malloc
    beqz         a0,d5_die
    mv           s5,a0                                             # s5 contains the update array

# we memset this one every new line of updates
    li           a0,100
    call         malloc
    beqz         a0,d5_die
    mv           s6,a0                                             # bool array

d5p1_parse_rules:
    mv           a0,s1                                             # input
    mv           a1,s3                                             # rules array
    mv           a2,s4                                             # rules len array
    call         parse_rules                                       # populate array
    mv           s1,a0                                             # update s1 so we can parse the updates
d5p1_parse_updates_outer_loop:
    beq          s1,s2,d5p1_done                                   # out of input, all done!

    mv           a0,s6                                             # move bool array ptr into a0
    li           a1,0                                              # value to set all elements
    li           a2,100                                            # num elements
    call         memset                                            # clear the bool array

    mv           a0,s1                                             # setup for call
    mv           a1,s5                                             # array to parse into
    call         parse_updates                                     # parse updates into the update array
    mv           s1,a0                                             # update input pointer for next set of updates

d5p1_check_update:
    srli         a7,a1,1                                           # index to middle element

    mv           a0,s5                                             # array of updates
    mv           a1,a1                                             # nop but len of array of updates
    mv           a2,s6                                             # bool array
    mv           a3,s3                                             # rule array
    mv           a4,s4                                             # rule_len array
    call         validate_update_set
    beqz         a0,d5p1_parse_updates_outer_loop                  # invalid, move on to next update set

d5p1_check_update_done: # otherwise valid, add middle element to s0
    add          t0,s5,a7                                          # addr of middle elemnt
    lb           t0,(t0)                                           # t0 = *ptr
    add          s0,s0,t0                                          # add middle element to s0
    j            d5p1_parse_updates_outer_loop


d5p1_done:
    la           a0,part1_fmt
    mv           a1,s0
    call         printf

# free all the arrays
    mv           a0,s3
    call         free
    mv           a0,s4
    call         free
    mv           a0,s5
    call         free
    mv           a0,s6
    call         free

    AOC_EPILOGUE
    ret

# This is basically the same thing as part 1
# _but_ we skip initially valid sets and
# when we get an invalid update set
# then we bubble sort the invalid elements
# upwards and validate again until we
# have a valid set (this is why validate_update_set returns
# the index of the invalid element. so we can swap it upwards
# and recheck)
# then once its validated we just grab the middle element like before
day5_part2:
    AOC_PROLOGUE

d5p2_setup:
# this is all the same as in p1, we're just setting up
# the save registers and a bunch of arrays we will need
    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr
    li           a0,3000                                           # 30 elements x 100 values
    call         malloc
    beqz         a0,d5_die
    mv           s3,a0                                             # store the rules array in s3
    li           a1,0
    li           a2,3000
    call         memset                                            # zero the rules array

    li           a0,100                                            # 100 values, num elements in s3 per value
    call         malloc
    beqz         a0,d5_die
    mv           s4,a0                                             # store lengths array in s4
    li           a1,0
    li           a2,100
    call         memset                                            # zero the lengths array

# don't need to memset this one because our parser returns len()
    li           a0,30                                             # over allocate array for updates
    call         malloc
    beqz         a0,d5_die
    mv           s5,a0                                             # s5 contains the update array

# we memset this one every new line of updates so don't memset here
    li           a0,100
    call         malloc
    beqz         a0,d5_die
    mv           s6,a0                                             # bool array

d5p2_parse_rules:
    mv           a0,s1                                             # input
    mv           a1,s3                                             # rules array
    mv           a2,s4                                             # rules len array
    call         parse_rules                                       # populate array
    mv           s1,a0                                             # update s1 so we can parse the updates
d5p2_parse_updates_outer_loop:
    beq          s1,s2,d5p2_done                                   # out of input, all done!

    mv           a0,s6                                             # move bool array ptr into a0
    li           a1,0                                              # value to set all elements
    li           a2,100                                            # num elements
    call         memset                                            # clear the bool array

    mv           a0,s1                                             # setup for call
    mv           a1,s5                                             # array to parse into
    call         parse_updates                                     # parse updates into the update array
    mv           s1,a0                                             # update input pointer for next set of updates

d5p2_check_update:
    mv           a7,a1                                             # save this for later

    mv           a0,s5                                             # array of updates
    mv           a1,a1                                             # nop but len of array of updates
    mv           a2,s6                                             # bool array
    mv           a3,s3                                             # rule array
    mv           a4,s4                                             # rule_len array
    call         validate_update_set
    bnez         a0,d5p2_parse_updates_outer_loop                  # valid, so for p2 move on to next update set

d5p2_fix_update_set: # there's a problem so let's bubble up problem until it's not
# swap the problem element with a later element
    mv           a0,s5                                             # get ready for next validate_call
    add          t0,a0,a1                                          # problem element ptr
    addi         t1,a1,1                                           # next element index
    add          t1,a0,t1                                          # next element ptr
    lb           t2,(t0)                                           # t2 = *problem
    lb           t3,(t1)                                           # t3 = *not problem
    sb           t2,(t1)                                           # swap the elements!
    sb           t3,(t0)

# clear the bool array to revalidate
    mv           s7,a7                                             # save for after memset
    mv           a0,s6                                             # move bool array ptr into a0
    li           a1,0                                              # value to set all elements
    li           a2,100                                            # num elements
    call         memset                                            # clear the bool array
    mv           a7,s7                                             # restore a7

    mv           a0,s5                                             # update array not bool array
    mv           a1,a7                                             # length of update array
    mv           a2,s6                                             # bool array
    mv           a3,s3                                             # rule array
    mv           a4,s4                                             # rule_len array
    call         validate_update_set
    beqz         a0,d5p2_fix_update_set                            # still invalid so bubble next issue

# valid set now, add middle element!
    srli         a7,a7,1                                           # middle element index
    add          t0,s5,a7                                          # middle element ptr
    lb           t0,(t0)                                           # get the middle element
    add          s0,s0,t0
    j            d5p2_parse_updates_outer_loop


d5p2_done:
    la           a0,part2_fmt
    mv           a1,s0
    call         printf

d5p2_teardown:
# free all the arrays
    mv           a0,s3
    call         free
    mv           a0,s4
    call         free
    mv           a0,s5
    call         free
    mv           a0,s6
    call         free

    AOC_EPILOGUE
    ret


    .equ         PIPE, '|'
    .equ         NEWLINE, '\n'

# Parse the ruleset into given memory blocks
# memory assumed to be sized properly ahead of time
# input assumed to have a "\n\n" so we don't check
# when we're going out of bounds
# a0 - input
# a1 - rules array
# a2 - rules len array
# AFTER:
# a0 points to 1 after rules (input)
# arrays are populated and ready to check input
# NOTE: we're totally gonna just stomp the
# a* registers without saving them because
# they're not being used at this point
parse_rules:
    addi         sp,sp,-16
    sw           ra,(sp)                                           # need to save off ra b/c we call parse_int

    mv           a5,a0                                             # save these off
    mv           a6,a1                                             # so we can use
    mv           a7,a2                                             # a0-a2 for parsing ints
parse_rules_iter:
    mv           a0,a5                                             # get ready for parse_int
# XX|YY\n -> XX is index into rules array, YY is added to that
    call         parse_int                                         # a0 is now XX
    mv           a4,a0                                             # save off XX so we can parse YY
    mv           a5,a1                                             # update the input pointer, should be '|' now
    lb           t0,(a5)                                           # should be a '|'
    addi         t0,t0,-PIPE
    bnez         t0,d5_die                                         # wasn't a pipe where are we?
    addi         a5,a5,1
    mv           a0,a5
    call         parse_int                                         # a0 is now YY
    mv           a5,a1                                             # save off input again *a5 should be '\n'
    lb           a1,(a5)                                           # a1 is *a5
    addi         a1,a1,-NEWLINE
    bnez         a1,d5_die                                         # wasn't newline, where are we?
    addi         a5,a5,1                                           # skip the newline, a5 is either at newline (done) or next XX

# now parse XX | YY rules
# XX is in a4
# YY is in a0
    li           t1,30                                             # rules array is 30 elements per value inline
    mul          t0,a4,t1                                          # t0 is offset into rules array for XX
    add          t0,a6,t0                                          # t0 is pointer into rules array for XX
    add          t1,a7,a4                                          # t1 is pointer into the rules len array
    lb           t2,(t1)                                           # t2 is extra offset for next rule len = rules_len[XX]
    add          t0,t0,t2                                          # t0 now points to where to insert next ( aka &rules_arr[XX][len])
    sb           a0,(t0)                                           # rules_arr[XX][len] = YY
    addi         t2,t2,1                                           # len += 1
    sb           t2,(t1)                                           # rules_len[XX] = len (we added a rule!)

    lb           a0,(a5)
    addi         a0,a0,-NEWLINE
    bnez         a0,parse_rules_iter                               # when we're not on an empty line now, parse next rule

parse_rules_done:
    addi         a0,a5,1                                           # should now point at the first set of updates

    lw           ra,(sp)                                           # restore ra
    addi         sp,sp,16
    ret

# Parse a single line of updates into
# the provided array. returns pointer
# past the line and length of updates parsed
# a0 - input
# a1 - array to parse into
# RETURNS:
# a0 - pointer after updates
# a1 - number updates parsed
parse_updates:
    addi         sp,sp,-16
    sw           ra,(sp)                                           # need to save off ra b/c we call parse_int

    mv           a5,a0
    mv           a6,a1
    li           a4,0                                              # number of updates

parse_updates_loop:
    mv           a0,a5
    call         parse_int
    mv           a5,a1
    sb           a0,(a6)                                           # store the value into the array
    addi         a6,a6,1                                           # increment array pointer
    addi         a4,a4,1                                           # increment number of elements in array
    lb           t0,(a5)                                           # what is the value we're at? options: '\n' or ','
    addi         t0,t0,-NEWLINE
    beqz         t0,parse_updates_done                             # newline, we're done
    addi         a5,a5,1                                           # skip ','
    j            parse_updates_loop                                # keep parsing updates

parse_updates_done:
    addi         a0,a5,1                                           # skip the newline we found
    mv           a1,a4                                             # number of updates we parsed

    lw           ra,(sp)                                           # restore ra
    addi         sp,sp,16
    ret

# breaking this out into its own function
# since it's reused in p2 a lot
# a0 - the update array ptr
# a1 - update array len
# a2 - bool array (zeroed ahead of time)
# a3 - rule array
# a4 - rule_len array
# this will stomp all a* registers other than a7
# RETURNS
# a0 - 1 if valid else 0
# a1 - index of element that failed if a0 is 0
validate_update_set:
validate_update_set_check_updates_loop_decr:
    addi         a1,a1,-1                                          # reverse iterate updates starting at len-1 (last element)
validate_update_set_check_updates_loop:
    bltz         a1,validate_update_set_valid                      # idx < 0, all done
    add          t0,a0,a1                                          # reverse iterate elements
    lb           t0,(t0)                                           # t0 = update_array[a1]
    add          t1,a2,t0                                          # index into the bool array "did this need to come after"
    lb           t1,(t1)                                           # get the bool value
    bnez         t1,validate_update_set_invalid                    # this isn't a valid set of updates

# for each value that has to be after this one, set it true in the bool array
    mv           t2,t0                                             # t2 = update_array[a1] aka offset into the rules len array
    li           t1,30                                             # rules array is 30 elements per value inline
    mul          t0,t0,t1                                          # offset into rules array
    add          t3,a3,t0                                          # ptr1 = pointer into rules_array for update_array[a1]
    add          t4,a4,t2                                          # ptr2 = pointer into rule_len array for update_array[a1]
    lb           a6,(t4)                                           # get length of rules in rules array
    add          a6,t3,a6                                          # a6 is now a pointer that is the end of the rules array
# a4 is our pointer to the rules
# a6 is the pointer to the end of the rules
validate_update_set_add_rules_loop:
    beq          t3,a6,validate_update_set_check_updates_loop_decr # done adding rules, check next update
    lb           t0,(t3)                                           # t0 = *rule_ptr
    add          t1,a2,t0                                          # bool_ptr = bool_array + rule value
    li           t2, 1                                             # true
    sb           t2,(t1)                                           # set the bool to true in the array
    addi         t3,t3,1                                           # increment the rules ptr
    j            validate_update_set_add_rules_loop

validate_update_set_valid:
    li           a0,1
    ret
validate_update_set_invalid:
    li           a0,0
    mv           a1,a1                                             # nop but just being explicit
    ret

d5_die:
    call         unreachable
