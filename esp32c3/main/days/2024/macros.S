    .macro AOC_PROLOGUE
    addi   sp,sp,-64
    sw     ra,0(sp)
    sw     fp,4(sp)
    sw     s1,8(sp)
    sw     s2,12(sp)
    sw     s3,16(sp)
    sw     s4,20(sp)
    sw     s5,24(sp)
    sw     s6,28(sp)
    sw     s7,32(sp)
    sw     s8,36(sp)
    sw     s9,40(sp)
    sw     s10,44(sp)
    .endm

    .macro AOC_EPILOGUE
    lw     ra,0(sp)
    lw     fp,4(sp)
    lw     s1,8(sp)
    lw     s2,12(sp)
    lw     s3,16(sp)
    lw     s4,20(sp)
    lw     s5,24(sp)
    lw     s6,28(sp)
    lw     s7,32(sp)
    lw     s8,36(sp)
    lw     s9,40(sp)
    lw     s10,44(sp)
    addi   sp,sp,64
    .endm