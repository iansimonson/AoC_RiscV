    .global is_digit,string_eq,parse_int_range,parse_int,sort_int

    .equ    ZERO, 48
    .equ    COLON, 58          # because COLON is one after '9'
    .equ    NEWLINE, 0x0a

    .text

# returns 1 if a0 is an ascii digit
# a0 - byte
# tramples a0, t0, and t1
is_digit:
    slti    t0,a0,ZERO
    xori    t0,t0,1
    slti    t1,a0,COLON
    and     a0,t0,t1
    ret

# Compare two strings
# a0 - data1
# a1 - len1
# a2 - data2
# a3 - len2
# tramples t0,t1
string_eq:
    bne     a1,a3,done_false
string_eq_loop:
    beqz    a1,done_true
    lb      t0,(a0)
    lb      t1,(a2)
    bne     t0,t1,done_false
    addi    a0,a0,1
    addi    a2,a2,1
    addi    a1,a1,-1
    j       string_eq_loop
done_true:
    li      a0,1
    ret
done_false:
    li      a0,0
    ret

# Parses a string to an integer
# starting at position a0
# with a1 being the end (1 past number)
# a0 - begin
# a1 - end
# RETURNS:
# a0 - value
parse_int_range:
    li      t1,10
    mv      t2,a0
    mv      t3,a1
    li      a0,0
    li      a1,0
    j       parse_int_loop
parse_int_range_loop_iter:
    addi    t2,t2,1
parse_int_range_loop:
    beq     t2,t3,parse_int_done
    lb      a1,(t2)
    addi    a1,a1,-ZERO
    mul     a0,a0,t1
    add     a0,a0,a1
    j       parse_int_loop_iter
parse_int_range_done:
    ret

# Parses a string to an integer
# but only with the start of the number
# parses until the end of the number (!is_digit)
# a0 - start of number
# undefined behavior if the number goes
# off the end of the string
# RETURNS:
# a0 - value
# a1 - pointer to end of number (1 past the end)
parse_int:
    li      t4,10
    mv      t5,a0
    li      a0,0
    li      a1,0
    j       parse_int_loop
parse_int_loop_iter:
    addi    t5,t5,1
parse_int_loop:
    lb      a1,(t5)
    
    slti    t0,a1,ZERO # is_digit inlined
    xori    t0,t0,1
    slti    t1,a1,COLON
    and     t3,t0,t1
    beqz    t3,parse_int_done # if !is_digit break

    addi    a1,a1,-ZERO # otherwise keep parsing int
    mul     a0,a0,t4
    add     a0,a0,a1
    j       parse_int_loop_iter
parse_int_done:
    mv a1,t5 # ptr to 1 past the number (end)
    ret

# recursive quick_sort function
# for things that are int size
# e.g. int
# a0 - Array
# a1 - lo - inclusive (index, not byte size)
# a2 - hi - inclusive
quick_sort_int:
    .equ IDX_SIZE, 4 # int size (4 bytes)
    bge a1,a2,qs_done_early
    bltz a1,qs_done_early
    
    addi    sp,sp,-32 # prologue
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)

    mv s1,a1 # save lo for later
    mv s2,a2 # save hi

    slli a1,a1,2 # byte size
    slli a2,a2,2

qs_partition:
    add t0,a0,a2 # t0 = A + hi (last element)
    mv t3,t0 # t3 = end = hi
    lw t0,(t0) # pivot = A[hi]
    slli t1,s1,2 # pivot index is lo
    mv t2,t1 # for j = lo
    j qs_partition_loop
qs_partition_loop_incr:
    addi t2,t2,IDX_SIZE # j += 1
qs_partition_loop:
    add a3,a0,t2 # A + j
    beq a3,t3,qs_partition_loop_done
    lw t4,(a3) # t4 = A[j]
    bgt t4,t0,qs_partition_loop_incr
    add t5,a0,t1 # t5 = A + i
    lw a4,(t5) # swap A[i] with A[j]
    sw t4,(t5)
    sw a4,(a3)
    addi t1,t1,IDX_SIZE
    j qs_partition_loop_incr
qs_partition_loop_done:
    add t5,a0,t1 # t5 = A + pivot index (i)
    lw t4,(t3) # t4 = A[hi]
    lw a4,(t5) # a4 = A[i]
    sw a4,(t3)
    sw t4,(t5)

    srli s3,t1,2 # save off pivot index as index
    mv a1,s1 # lo = lo
    addi a2,s3,-1 # hi = p - 1
    call quick_sort_int
    addi a1,s3,1 # lo = p + 1
    mv a2,s2 # hi = hi
    call quick_sort_int

qs_done:
    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    addi    sp,sp,32 # epilogue

qs_done_early:
    ret


# Sorts an array with signed 32-bit integers
# a0 - ptr to start
# a1 - length  of array (in integers not bytes!)
# AFTER:
# a0 is sorted
sort_int:
    beqz a1,sort_int_done
    mv t0,a1
    li a1,0 # starting index == 0
    addi a2,t0,-1 # hi = length - 1
    mv a7,ra # save return register b/c quick_sort doesn't use a7
    call quick_sort_int
    mv ra,a7 # restore the ra
sort_int_done:
    ret
