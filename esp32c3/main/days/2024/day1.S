    .global day1_part1,day1_part2,printf,sort_int

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
count_newlines: # while input_ptr < end
    beq a0,s2,count_newlines_done # if input_ptr == end break
    lb t0,(a0) # t0 = *input
    seqi t1,t0,NEWLINE # t1 = 1 if t0 == '/n' else 0
    addi a2,a2,t1 # a2 = a2 + t1 (+1 if it was a '/n')
    j count_newlines # keep looping
count_newlines_done:
    slli a2,a2,2 # we can store as words a2 << 2
    mv s3,a2 # store the byte size in s3 so we can adjust the stack later
    sub sp,sp,s3 # first array
    mv s4,sp
    sub sp,sp,s3
    mv s5,sp # second array
parse_arrays:
    mv a6,s4 # a6 is (first_arr + i)
    mv a7,s5 # a7 is (second_arr + i)
    mv a0,s2 # a0 = input
parse_array_loop:
    bge a0,s3,parse_array_done
    call parse_int # a0 = int starting at a0, a1 = 1 past end
    sw a0,(a6) # first_arr[0] = a0
    addi a0,a1,1 # a1 was a space, a0 now at the next number
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

day1_part2:
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
