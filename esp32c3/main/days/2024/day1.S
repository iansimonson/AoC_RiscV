    .global day1_part1,day1_part2,printf,sort_int,malloc,free

    .equ NEWLINE, 0x0a

# OK we don't have a dynamic array
# type or anything because it's assembly
# SO. we're going to do the following
# 1. count how many elements each list is (count newlines)
# 2. alloca (stack arrays) for both lists
# 3. parse the input into the two lists
# 4. sort the lists
# 5. loop through and sum the abs of the differences
# INPUTS -
# a0 - input ptr
# a1 - input len
day1_part1:
    addi    sp,sp,-32 # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)
    sw      s4,20(sp)
    sw      s5,24(sp)

    li s0,0 # s0 == result
    mv s1,a0 # s1 == input ptr
    add s2,a0,a1 # s2 == end ptr
    li s3,0 # byte_size of array
    li s4,0 # first array
    li s5,0 # second array

    li a2,0
    li t2,NEWLINE
count_newlines: # while input_ptr < end
    beq a0,s2,count_newlines_done # when input_ptr == end break
    lb t0,(a0) # t0 = *input
    addi a0,a0,1
    addi t0,t0,-NEWLINE # t0 = t0 - '/n' (t0 == '/n' ?)
    seqz t1,t0 # t1 = 1 if t0 == '/n' else 0
    add a2,a2,t1 # a2 = a2 + t1 (+1 if it was a '/n')
    j count_newlines # keep looping
count_newlines_done:
    slli a2,a2,2 # we can store as words a2 << 2
    mv s3,a2 # store the byte size in s3 so we can adjust the stack later
    mv a0,s3
    call malloc
    beqz a0,d1_die
    mv s4,a0 # first array
    mv a0,s3
    call malloc
    beqz a0,d1_die
    mv s5,a0 # second array
parse_arrays:
    mv a6,s4 # a6 is (first_arr + i)
    mv a7,s5 # a7 is (second_arr + i)
    mv a0,s1 # a0 = input
parse_array_loop:
    bge a0,s2,parse_array_done
    call parse_int # a0 = int starting at a0, a1 = 1 past end
    sw a0,(a6) # first_arr[0] = a0
    addi a0,a1,3 # a1 was a space, a0 now at the next number
    addi a6,a6,4 # first_arr += 1
    call parse_int
    sw a0,(a7) # second_arr[0] = a0
    addi a0,a1,1 # a1 was a newline, now it's the next line
    addi a7,a7,4 # second_arr += 1
    j parse_array_loop
parse_array_done:
    mv a0,s4
    srli a1,s3,2
    call sort_int # sort first_arr
    mv a0,s5
    srli a1,s3,2
    call sort_int # sort second_arr
    li a0,0 # index into arrays for i = 0
    j sum_abs_diffs
sum_abs_diffs_incr:
    addi a0,a0,4 # i += 1
sum_abs_diffs:
    beq a0,s3,sum_abs_diffs_done # i != len(first_arr)
    add a1,s4,a0 # first_arr + i
    add a2,s5,a0 # second_arr + i
    lw t0,(a1)
    lw t1,(a2)
    sub t0,t0,t1 # fa[i] - sa[i]
    bgez t0,sum_abs_diffs_add
    neg t0,t0
sum_abs_diffs_add:
    add s0,s0,t0
    j sum_abs_diffs_incr
sum_abs_diffs_done:
    la a0,d1p1_fmt
    mv a1,s0
    call printf

    mv a0,s4 # free array 1
    call free
    mv a0,s5 # free array 2
    call free

    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    lw      s4,20(sp)
    lw      s5,24(sp)
    addi    sp,sp,32 # epilogue
    ret

# OK so same as above, except we
# need to do some pointer tracking
# and just add those numbers while
# the number is the same
# INPUTS -
# a0 - input ptr
# a1 - input len
day1_part2:
    addi    sp,sp,-32 # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)
    sw      s4,20(sp)
    sw      s5,24(sp)

    li s0,0 # s0 == result
    mv s1,a0 # s1 == input ptr
    add s2,a0,a1 # s2 == end ptr
    li s3,0 # byte_size of array
    li s4,0 # first array
    li s5,0 # second array

    li a2,0
    li t2,NEWLINE
d1p2_count_newlines: # while input_ptr < end
    beq a0,s2,d1p2_count_newlines_done # when input_ptr == end break
    lb t0,(a0) # t0 = *input
    addi a0,a0,1
    addi t0,t0,-NEWLINE # t0 = t0 - '/n' (t0 == '/n' ?)
    seqz t1,t0 # t1 = 1 if t0 == '/n' else 0
    add a2,a2,t1 # a2 = a2 + t1 (+1 if it was a '/n')
    j d1p2_count_newlines # keep looping
d1p2_count_newlines_done:
    slli a2,a2,2 # we can store as words a2 << 2
    mv s3,a2 # store the byte size in s3 so we can adjust the stack later
    sub sp,sp,s3 # first array
    mv s4,sp
    sub sp,sp,s3
    mv s5,sp # second array
d1p2_parse_arrays:
    mv a6,s4 # a6 is (first_arr + i)
    mv a7,s5 # a7 is (second_arr + i)
    mv a0,s1 # a0 = input
d1p2_parse_array_loop:
    bge a0,s2,d1p2_parse_array_done
    call parse_int # a0 = int starting at a0, a1 = 1 past end
    sw a0,(a6) # first_arr[0] = a0
    addi a0,a1,3 # a1 was a space, a0 now at the next number
    addi a6,a6,4 # first_arr += 1
    call parse_int
    sw a0,(a7) # second_arr[0] = a0
    addi a0,a1,1 # a1 was a newline, now it's the next line
    addi a7,a7,4 # second_arr += 1
    j d1p2_parse_array_loop
d1p2_parse_array_done:
    mv a0,s4
    srli a1,s3,2
    call sort_int # sort first_arr
    mv a0,s5
    srli a1,s3,2
    call sort_int # sort second_arr
    li a0,0 # index into arrays for i = 0
    j calc_simularity_score
# on left side - pointer to array
# check value, is it the same as before?
# when not, try finding it in right array
# when found, count number exists
# while number on left side is same, just add value
# repeat
calc_simularity_score:
    mv a3,s4 # first array pointer in a3
    add a4,a3,s3 # end of first array
    mv a5,s5 # second array pointer into a5
    add a6,a5,s3 # second array end into a6
    j calc_simularity_score_loop
calc_simularity_score_loop_incr:
    addi a3,a3,4 # p1 += 1
calc_simularity_score_loop:
    bge a3,a4,calc_simularity_score_done
    lw t0,(a3)
css_find_in_arr2:
    bge a5,a6,calc_simularity_score_done # when p2 past end of arr2 done
    lw t1,(a5)
    beq t0,t1,css_count_in_arr2
    blt t0,t1,calc_simularity_score_loop_incr # when *p1 < *p2 then *p1 not in arr2
    addi a5,a5,4 # next index
    j css_find_in_arr2
css_count_in_arr2:
    mv a0,a5 # starting pointer
css_count_in_arr2_loop_incr:
    addi a5,a5,4 # p2 += 1
css_count_in_arr2_loop:
    bge a5,a6,css_count_in_arr2_done
    lw t1,(a5)
    bgt t1,t0,css_count_in_arr2_done
    j css_count_in_arr2_loop_incr
css_count_in_arr2_done:
    sub a0,a5,a0 # ptr - start = count in arr2
    srli a0,a0,2 # byte count -> count of ints
    mul a0,a0,t0 # score we care about is t0 * count
css_add_left_arr: # increment p1 and add a0 until we're at a new number
    add s0,s0,a0 # result += a0
    add a3,a3,4
    bge a3,a4,calc_simularity_score_done
    lw t2,(a3) # new value
    bne t0,t2,calc_simularity_score_loop
    j css_add_left_arr
calc_simularity_score_done:
    la a0,d1p2_fmt
    mv a1,s0
    call printf

    add sp,sp,s3 # free second_arr
    add sp,sp,s3 # free first_arr
    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    lw      s4,20(sp)
    lw      s5,24(sp)
    addi    sp,sp,32 # epilogue
    ret

d1_die:
    la a0,d1_die_fmt
    call printf
d1_die_loop:
    j d1_die_loop


    .data
d1_die_fmt: .string "HOW DID WE GET HERE?"
d1p1_fmt: .string "Part1: %d\n"
d1p2_fmt: .string "Par2: %d\n"
