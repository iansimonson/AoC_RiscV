#include "macros.S"
    .global dayX_part1,dayX_part2 # this file
    .global printf,malloc,memset # libc
    .global is_digit,string_eq,parse_int_range # begin utility.S
    .global parse_int,sort_int,part1_fmt,part2_fmt
    .global grid_load_neighbor_offsets,grid_find_width
    .global unreachable # end utility.S

    .text
dayX_part1:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr


dXp1_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

dayX_part2:
    AOC_PROLOGUE

    li           s0,0                                              # result
    mv           s1,a0                                             # input
    add          s2,a0,a1                                          # end ptr


dXp2_done:
    la a0,part1_fmt
    mv a1,s0
    call printf

    AOC_EPILOGUE
    ret

dayX_die:
    call unreachable


    .data # any useful globals (r/w)
