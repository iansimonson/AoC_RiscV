    .global day2_part1,day2_part2

# as constants gcc replaces these
    .equ    ZERO, 48
    .equ    COLON, 58                  # because COLON is one after '9'
    .equ    NEWLINE, 0x0a
    .equ    LOWERCASE_R, 114
    .equ    LOWERCASE_G, 103
    .equ    LOWERCASE_B, 98

    .text

# Check each game to see if
# all reds <= 12, all greens <= 13
# and all blues <= 14
# sum the game ids for all lines
# that are valid
# a0 - input
# a1 - input_len
day2_part1:
# value +1 b/c instruction is lt not le
# (le is a 2 instruction pseudo instruction)
    .equ    MAX_RED, 13
    .equ    MAX_GREEN, 14
    .equ    MAX_BLUE, 15

# prologue
    addi    sp,sp,-24
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)

    mv      s1,a0                      # s1 = input
    add     s2,a0,a1                   # s2 = input + length (end)
    li      s3,0                       # result to print
    j       d2p1_outer_loop

d2p1_outer_loop_incr:
    addi    s1,s1,1                    # input += 1
d2p1_outer_loop: # for line in lines kinda
    beq     s1,s2,d2p1_done
d2p1_find_id_digit:
    lb      a0,(s1)
    call    is_digit
    bnez    a0,d2p1_parse_id           # if '0' <= *input <= '9' parse_game_id()
    addi    s1,s1,1                    # else input += 1
    j       d2p1_find_id_digit
d2p1_parse_id:
    li      a7,0                       # store game id in a7
d2_p1_parse_id_loop:
    lb      a0,(s1)
    mv      a1,a0
    call    is_digit
    beqz    a0,d2p1_validate_game      # if !is_digit(*input) we're done parsing game_id
    addi    a1,a1,-ZERO                # else x: u8 = *input - '0'
    li      t4,10
    mul     a7,a7,t4                   # game_id = game_id * 10 + x
    add     a7,a7,a1
    addi    s1,s1,1                    # input += 1
    j       d2_p1_parse_id_loop
d2p1_validate_game:
    li      t5,NEWLINE
    addi    s1,s1,1                    # we know from before *s1 is not a digit
    lb      a0,(s1)
    beq     a0,t5,d2p1_game_validated  # end of line, finish processing game
    call    is_digit                   # if !is_digit then
    beqz    a0,d2p1_validate_game      # loop until we find a digit
# found digit
    li      a6,0                       # store number of cubes in a6
d2p1_parse_color_amt:
    lb      a0,(s1)
    mv      a1,a0                      # we store in a0 and a1 because is_digit uses a0
    call    is_digit
    beqz    a0,d2p1_validate_color     # if !is_digit then check color
    addi    a1,a1,-ZERO                # x : = *input - '0'
    li      t4,10                      # there is no muli so load 10 into t4
    mul     a6,a6,t4                   # value *= 10
    add     a6,a6,a1                   # value += digit
    addi    s1,s1,1                    # input += 1
    j       d2p1_parse_color_amt
d2p1_validate_color:
# wasn't a digit so it's the space
# colors start with unique letters so only have
# to check the first letter r, g, or b
# In future maybe will try this with jump table
    addi    s1,s1,1                    # now pointing at color word
    lb      a0,(s1)                    # color : = *input
    mv      a1,a0                      # save it off into a1 so we don't have to load again
    addi    a0,a0,-LOWERCASE_R         # a0 : = color - 'r'
    beqz    a0,d2p1_check_red          # a0 == 0 aka (color == 'r')
    mv      a0,a1
    addi    a0,a0,-LOWERCASE_G         # a0 : = color - 'g'
    beqz    a0,d2p1_check_green
    mv      a0,a1
    addi    a0,a0,-LOWERCASE_B         # a0 : = color - 'b'
    beqz    a0,d2p1_check_blue
    j       d2_UNREACHABLE             # wasn't r,g, or b so ERROR
d2p1_check_red: # MAX_RED = maximum # of reds + 1 b/c <= is 2 instructions
    slti    t2,a6,MAX_RED              # t2 : = 1 if a6 < MAX_RED else 0
    beqz    t2,d2p1_skip_newline
    j       d2p1_validate_game         # amount ok, keep validating game
d2p1_check_green: # see check_red but for green
    slti    t2,a6,MAX_GREEN
    beqz    t2,d2p1_skip_newline
    j       d2p1_validate_game
d2p1_check_blue: # see check_red but for blue
    slti    t2,a6,MAX_BLUE
    beqz    t2,d2p1_skip_newline
    j       d2p1_validate_game
# NOTE: for r64 this would be an interesting one
# in the future to try out vector instructions
# _but_ for now this should be compatible with esp32c3
# so only IM allowed
d2p1_skip_newline: # game is invalid so we can just skip the line
    li      t0,NEWLINE                 # t0 : = '/n'
    lb      a0,(s1)                    # a0 : = *input
    beq     a0,t0,d2p1_outer_loop_incr # if a0 == t0 end of line, start next line
    addi    s1,s1,1                    # input += 1
    j       d2p1_skip_newline          # continue skipping to newline
d2p1_game_validated:
    add     s3,s3,a7                   # sum += game id
# la a0,d2p1_debug_fmt # debug printing
# mv a1,a7
# call printf
    j       d2p1_outer_loop_incr       # check next line

d2p1_done:
    la      a0,d2p1_fmt
    mv      a1,s3
    call    printf

# epilogue
    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    addi    sp,sp,24
    ret

# Check the max value of each
# r, g, b, from each game
# multiply them and sum
# we no longer care about game id
# so we're going to look for COLON
# instead
day2_part2:
# prologue
    addi    sp,sp,-32
    sw      ra,0(sp)
    sw      fp,4(sp)
    sw      s1,8(sp)
    sw      s2,12(sp)
    sw      s3,16(sp)
    sw      s4,20(sp)
    sw      s5,24(sp)

    mv      s1,a0                      # s1 = input
    add     s2,a0,a1                   # s2 = input + length (end)
    li      s0,0                       # result to print
    j       d2p2_outer_loop

d2p2_outer_loop_incr:
    add     s1,s1,1                    # input += 1
d2p2_outer_loop:
    beq     s1,s2,d2p2_done            # if input == end break outer loop
    li      s3,0                       # store per-game red max
    li      s4,0                       # store per-game green max
    li      s5,0                       # store per-game blue max
d2p2_skip_colon:
    lb      a0,(s1)                    # a0 : = input[0]
    addi    a0,a0,-COLON
    beqz    a0,d2p2_find_power
    addi    s1,s1,1
    j       d2p2_skip_colon
d2p2_find_power: # for each red, green, blue, find max value
    addi    s1,s1,1                    # we know from before *s1 is not a digit
    li      t5,NEWLINE                 # t5 : = '/n'
    lb      a0,(s1)                    # a0 : = input[0]
    beq     a0,t5,d2p2_add_power       # end of line, finish processing game
    mv      a1,a0
    call    is_digit
    beqz    a0,d2p2_find_power         # if !is_digit() continue parsing input
    addi    s1,s1,1                    # else we found a digit
    addi    a1,a1,-ZERO                # parse this digit immediately
    mv      a6,a1                      # a6 is where we will store this amount
d2p2_parse_power_amt:
    lb      a0,(s1)
    mv      a1,a0                      # we store in a0 and a1 because is_digit uses a0
    call    is_digit
    beqz    a0,d2p2_check_color        # if !is_digit then check color
    addi    a1,a1,-ZERO                # x : = *input - '0'
    li      t4,10                      # there is no muli so load 10 into t4
    mul     a6,a6,t4                   # value *= 10
    add     a6,a6,a1                   # value += digit
    addi    s1,s1,1                    # input += 1
    j       d2p2_parse_power_amt
d2p2_check_color:
# it's probably the space above if it's after the number
    addi    s1,s1,1
    lb      a0,(s1)
    mv      a1,a0                      # save it off into a1 so we don't have to load again
    addi    a0,a0,-LOWERCASE_R         # a0 : = color - 'r'
    beqz    a0,d2p2_check_red          # a0 == 0 aka (color == 'r')
    mv      a0,a1
    addi    a0,a0,-LOWERCASE_G         # a0 : = color - 'g'
    beqz    a0,d2p2_check_green
    mv      a0,a1
    addi    a0,a0,-LOWERCASE_B         # a0 : = color - 'b'
    beqz    a0,d2p2_check_blue
    j       d2_UNREACHABLE             # wasn't r,g, or b so ERROR
d2p2_check_red: # s3 : = max(s3, a6)
    slt     t2,s3,a6                   # t2 : = 1 if s3 < a6 else 0
    beqz    t2,d2p2_find_power         # s3 >= a6, nothing to do
    mv      s3,a6                      # s3 < a6 so s3 = a6 now
    j       d2p2_find_power            # find next power in game
d2p2_check_green: # see check_red but for green
    slt     t2,s4,a6                   # t2 : = 1 if s4 < a6 else 0
    beqz    t2,d2p2_find_power         # s4 >= a6, nothing to do
    mv      s4,a6                      # s4 < a6 so s4 = a6 now
    j       d2p2_find_power            # find next power in game
d2p2_check_blue: # see check_red but for blue
    slt     t2,s5,a6                   # t2 : = 1 if s5 < a6 else 0
    beqz    t2,d2p2_find_power         # s5 >= a6, nothing to do
    mv      s5,a6                      # s5 < a6 so s5 = a6 now
    j       d2p2_find_power            # find next power in game
d2p2_add_power:
    mul     t0,s3,s4                   # t3 = r * g
    mul     t0,t0,s5                   # t3 = t3 * b
    add     s0,s0,t0                   # power += t3
    j       d2p2_outer_loop_incr

d2p2_done:
    la      a0,d2p2_fmt
    mv      a1,s0
    call    printf

# epilogue
    lw      ra,0(sp)
    lw      fp,4(sp)
    lw      s1,8(sp)
    lw      s2,12(sp)
    lw      s3,16(sp)
    lw      s4,20(sp)
    lw      s5,24(sp)
    addi    sp,sp,32
    ret




# Functions that both parts might want to use

# Not really a function, this is more of a
# procedure which I then hotloop on
# for debugging
d2_UNREACHABLE:
    la      a0,unreachable_fmt
    call    printf
d2_die:
    j       d2_die

    .data
unreachable_fmt: .string "HOW DID WE GET HERE?\n"
d2p1_debug_fmt: .string "Game %d validated\n"
d2p1_fmt: .string "Part1: %d\n"
d2p2_fmt: .string "Part2: %d\n"
