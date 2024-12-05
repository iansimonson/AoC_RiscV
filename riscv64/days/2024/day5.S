#include "macro.S"

    .global day5_part1,day5_part2 # provided by this file
    .global printf,malloc,memset # from libc
    .global parse_int,unreachable # utility.S

    .text
# Every number is a 2 digit number, so we only have max 100,
# really 90 b/c 10-99 so we can just have an array
# make it an array of 30 elements each
# and a second array with the counts
# reverse iterate the lines
# each value, look up what numbers have to come _after_
# and mark them in a bool array (or bit array whatever)
# if a value has already been marked - BAD
# else we're ok, add the middle number
day5_part1:
    AOC_PROLOGUE

    # setup and create arrays for tracking rules
    # could have made these globals _but_
    # on esp32c3 I'm running out of sram and
    # malloc can use flash
    li s0,0 # result
    mv s1,a0 # input
    add s2,a0,a1 # end ptr
    li a0,3000 # 30 elements x 100 values
    call malloc
    beqz a0,d5_die
    mv s3,a0 # store the rules array in s3
    li a1,0
    li a2,3000
    call memset # zero the rules array

    li a0,100 # 100 values, num elements in s3 per value
    call malloc
    beqz a0,d5_die
    mv s4,a0 # store lengths array in s4
    li a1,0
    li a2,100
    call memset # zero the lengths array

    # don't need to memset this one because our parser returns len()
    li a0,30 # over allocate array for updates
    call malloc
    beqz a0,d5_die
    mv s5,a0 # s5 contains the update array

    # we memset this one every new line of updates
    li a0,100
    call malloc
    beqz a0,d5_die
    mv s6,a0 # bool array

d5p1_parse_rules:
    mv a0,s1 # input
    sub a1,s2,s1 # length
    mv a2,s3 # rules array
    mv a3,s4 # rules len array
    call parse_rules # populate array
    mv s1,a0 # update s1 so we can nparse the updates
d5p1_parse_updates_outer_loop:
    beq s1,s2,d5p1_done
    mv a0,s6
    li a1,0
    li a2,100
    call memset # clear the bool array

    mv a0,s1 # setup for call
    mv a1,s5 # array to parse into
    call parse_updates

    mv s1,a0 # update input pointer
    slli a7,a1,1 # index to middle element
d5p1_check_updates_loop_decr:
    addi a1,a1,-1 # len-1 (last  element in update array)
d5p1_check_updates_loop:
    bltz a1,d5p1_check_update_done
    add t0,s5,a1 # reverse iterate elements
    lb t0,(t0) # t0 = update_array[a1]
    add t1,s6,t0 # index into the bool array "did this need to come after"
    lb t1,(t1) # get the bool value
    bnez t1,d5p1_parse_updates_outer_loop # this isn't a valid set of updates
    # for each value that has to be after this one, set it true in the bool array
    mv t2,t0 # t2 = update_array[a1] aka offset into the rules len array
    li t1,30 # rules array is 30 elements per value inline
    mul t0,t0,t1 # offset into rules array
    add a4,s3,t0 # ptr1 = rules_array + offset
    add t3,s4,t2 # ptr2 = lengths_array + offset
    lb a6,(t3) # get length of rules in rules array
    add a6,a4,a6 # a6 is now a pointer that is the end of the rules array
    # a4 is our pointer to the rules
    # a6 is the pointer to the end of the rules
d5p1_add_rules_loop:
    beq a4,a6,d5p1_check_updates_loop_decr # done adding rules, check next update
    lb t0,(a4) # t4 = *rule_ptr
    add t1,s6,t0 # bool_ptr = bool_array + rule value
    li t2, 1 # true
    sb t2,(t1) # set the bool to true in the array
    addi a4,a4,1 # increment the rules ptr
    j d5p1_add_rules_loop

d5p1_check_update_done:
    add t0,s5,a7 # addr of middle elemnt
    lb t0,(t0)
    add s0,s0,t0 # add middle element to s0
    j d5p1_parse_updates_outer_loop


d5p1_done:
    la a0,part1_fmt
    mv a1,s0
    call printf
    AOC_EPILOGUE
    ret

day5_part2:
    ret


# Parse the ruleset into given memory blocks
# memory assumed to be sized properly ahead of time
# a0 - input
# a1 - length
# a2 - rules array
# a3 - rules len array
# AFTER:
# a0 points to 1 after rules (input)
# arrays are populated and ready to check input
parse_rules:
    ret

# Parse a single line of updates into
# the provided array. returns pointer
# past the line and length of updates parsed
# RETURNS:
# a0 - pointer after updates
# a1 - number updates parsed
parse_updates:
    ret

d5_die:
    call unreachable
