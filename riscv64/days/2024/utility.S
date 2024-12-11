    .global is_digit,string_eq,parse_int_range,parse_int,sort_int,part1_fmt,part2_fmt
    .global grid_load_neighbor_offsets,grid_find_width
    .global unreachable,ensure_character,parse_i64,parse_list_int
    .global clear_byte_range

    .equ    ZERO, 48
    .equ    COLON, 58                                                                 # because COLON is one after '9'
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

    slti    t0,a1,ZERO                                                                # is_digit inlined
    xori    t0,t0,1
    slti    t1,a1,COLON
    and     t3,t0,t1
    beqz    t3,parse_int_done                                                         # if !is_digit break

    addi    a1,a1,-ZERO                                                               # otherwise keep parsing int
    mul     a0,a0,t4
    add     a0,a0,a1
    j       parse_int_loop_iter
parse_int_done:
    mv      a1,t5                                                                     # ptr to 1 past the number (end)
    ret

# On riscv64 parse_int is already parsing
# register sized integers. But putting this
# here in case I want to expand it for esp32c3
# in which case it'll be a lot more work
parse_i64:
    j parse_int # j is ok here b/c it doesn't change any registers


# Parses a list of integers delimited
# by a single character (, or ' ' e.g.)
# until we hit newline
# The memory we parse into must be provided
# assume 32-bit values (no overflow checking)
# a0 - start of input
# a1 - pointer to array
# RETURNS:
# a0 - one past the end of list (skips newline)
# a1 - still pointer to array
# a2 - number of ints parsed
parse_list_int:
    mv a3,a0
    mv a4,a1
    li a6,0 # number of elements
pli_loop:
    mv a0,a3

    mv a7,ra # store off ra b/c we're about to call
    call parse_int
    mv ra,a7 # restore ra

    beq a1,a3,pli_loop_done # we didn't parse any int
    
    # parsed a new int
    mv a3,a1 # store the next input ptr
    mv t0,a4 # array to write into
    slli t1,a6,2 # turn int count into byte offset
    add t0,t0,t1 # offset into parse integer array
    sw a0,(t0) # store the integer we parsed
    addi a6,a6,1 # increment length now

    lb t0,(a3) # check what value we are at
    addi t0,t0,-NEWLINE # did we hit a newline?
    addi a3,a3,1 # either way skip the delimiter
    beqz t0,pli_loop_done # it was a newline, done
    j pli_loop # was not a newline, parse the next int

pli_loop_done:
    mv a0,a3 # input ptr
    mv a1,a4 # array
    mv a2,a6 # count of ints
    ret
    

# recursive quick_sort function
# for things that are int size
# e.g. int
# a0 - Array
# a1 - lo - inclusive (index, not byte size)
# a2 - hi - inclusive
quick_sort_int:
    .equ    IDX_SIZE, 4                                                               # int size (4 bytes)
    bge     a1,a2,qs_done_early
    bltz    a1,qs_done_early

    addi    sp,sp,-64                                                                 # prologue
    sd      ra,0(sp)
    sd      fp,8(sp)
    sd      s1,16(sp)
    sd      s2,24(sp)
    sd      s3,32(sp)

    mv      s1,a1                                                                     # save lo for later
    mv      s2,a2                                                                     # save hi

    slli    a1,a1,2                                                                   # byte size
    slli    a2,a2,2

qs_partition:
    add     t0,a0,a2                                                                  # t0 = A + hi (last element)
    mv      t3,t0                                                                     # t3 = end = hi
    lw      t0,(t0)                                                                   # pivot = A[hi]
    slli    t1,s1,2                                                                   # pivot index is lo
    mv      t2,t1                                                                     # for j = lo
    j       qs_partition_loop
qs_partition_loop_incr:
    addi    t2,t2,IDX_SIZE                                                            # j += 1
qs_partition_loop:
    add     a3,a0,t2                                                                  # A + j
    beq     a3,t3,qs_partition_loop_done
    lw      t4,(a3)                                                                   # t4 = A[j]
    bgt     t4,t0,qs_partition_loop_incr
    add     t5,a0,t1                                                                  # t5 = A + i
    lw      a4,(t5)                                                                   # swap A[i] with A[j]
    sw      t4,(t5)
    sw      a4,(a3)
    addi    t1,t1,IDX_SIZE
    j       qs_partition_loop_incr
qs_partition_loop_done:
    add     t5,a0,t1                                                                  # t5 = A + pivot index (i)
    lw      t4,(t3)                                                                   # t4 = A[hi]
    lw      a4,(t5)                                                                   # a4 = A[i]
    sw      a4,(t3)
    sw      t4,(t5)

    srli    s3,t1,2                                                                   # save off pivot index as index
    mv      a1,s1                                                                     # lo = lo
    addi    a2,s3,-1                                                                  # hi = p - 1
    call    quick_sort_int
    addi    a1,s3,1                                                                   # lo = p + 1
    mv      a2,s2                                                                     # hi = hi
    call    quick_sort_int

qs_done:
    ld      ra,0(sp)
    ld      fp,8(sp)
    ld      s1,16(sp)
    ld      s2,24(sp)
    ld      s3,32(sp)
    addi    sp,sp,64                                                                  # epilogue

qs_done_early:
    ret


# Sorts an array with signed 32-bit integers
# a0 - ptr to start
# a1 - length of array (in integers not bytes!)
# AFTER:
# a0 is sorted
sort_int:
    beqz    a1,sort_int_done
    mv      t0,a1
    li      a1,0                                                                      # starting index == 0
    addi    a2,t0,-1                                                                  # hi = length - 1
    mv      a7,ra                                                                     # save return register b/c quick_sort doesn't use a7
    call    quick_sort_int
    mv      ra,a7                                                                     # restore the ra
sort_int_done:
    ret

# THIS IS FOR ASCII GRIDS ONLY
# given a pointer to the beginning of a row in a grid
# return the width of the grid (including the newline)
# a0 - the pointer
# undefined if row doesn't end with newline or there's not
# enough input
# uses a0, t0, t1, and t2
grid_find_width:
    mv      t1,a0                                                                     # save off start of input
grid_find_width_loop:
    lb      t0,(a0)                                                                   # t0 = *input
    addi    t0,t0,-NEWLINE                                                            # t0 -= '/n'
    beqz    t0,grid_find_width_found
    addi    a0,a0,1
    j       grid_find_width_loop
grid_find_width_found:
    sub     t2,a0,t1                                                                  # t2 (width) = cur - start
    addi    t2,t2,1                                                                   # inclusive of the newline
    mv      a0,t2                                                                     # return result
    ret

# Loads an array with grid neighbor offsets
# array must be allocated ahead of time
# offsets are words (32-bit)
# offsets are:
# (-width-1) (-width) (-width+1)
# -1 cell 1
# (width-1) (width) (width+1)
# cell is NOT in the array, it's just to help
# the visual representation of each offset
# a0 - pointer
# a1 - grid width
grid_load_neighbor_offsets:
    sub     t0,zero,a1                                                                # -width
    addi    t1,t0,-1                                                                  # -width - 1 (upper left neighbor)
    sw      t1,(a0)                                                                   # store upper left offset
    sw      t0,4(a0)                                                                  # store upper offset
    addi    t1,t0,1                                                                   # -width + 1 (upper right neighbor)
    sw      t1,8(a0)                                                                  # store upper right neighbor
    li      t1,-1                                                                     # left neighbor
    sw      t1,12(a0)
    li      t1,1                                                                      # right neighbor
    sw      t1,16(a0)
    mv      t0,a1                                                                     # width
    addi    t1,t0,-1                                                                  # width - 1 bottom left neighbor
    sw      t1,20(a0)                                                                 # store bottom left
    sw      t0,24(a0)                                                                 # store bottom
    addi    t1,t0,1                                                                   # width + 1
    sw      t1,28(a0)                                                                 # bottom right neighbor
    ret

unreachable:
    la a0,unreachable_str
    call printf
unreachable_loop:
    j unreachable_loop

# memset but only uses a0 and a1
# a0 - start
# a1 - end
clear_byte_range:
    li t0,0
0:
    beq a0,a1,1f
    sb t0,(a0)
    addi a0,a0,1
    j 0b
1:
    ret

# calls unreachable if the character
# at the given pointer value is not
# the provided character
# INPUT:
# a0 - pointer to input ([^]u8)
# a1 - character to check against
ensure_character:
    lb t0,(a0)
    beq t0,a1,ensure_character_ok
    call unreachable
ensure_character_ok:
    ret

    .data
part1_fmt:
    .string "Part1: %d\n"
part2_fmt:
    .string "Part2: %d\n"
unreachable_str:
    .string "HOW DID WE GET HERE?\n"
