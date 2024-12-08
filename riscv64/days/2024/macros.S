    .macro AOC_PROLOGUE
    addi   sp,sp,-96
    sd     ra,0(sp)
    sd     fp,8(sp)
    sd     s1,16(sp)
    sd     s2,24(sp)
    sd     s3,32(sp)
    sd     s4,40(sp)
    sd     s5,48(sp)
    sd     s6,56(sp)
    sd     s7,64(sp)
    sd     s8,72(sp)
    sd     s9,80(sp)
    sd     s10,88(sp)
    .endm

    .macro AOC_EPILOGUE
    ld     ra,0(sp)
    ld     fp,8(sp)
    ld     s1,16(sp)
    ld     s2,24(sp)
    ld     s3,32(sp)
    ld     s4,40(sp)
    ld     s5,48(sp)
    ld     s6,56(sp)
    ld     s7,64(sp)
    ld     s8,72(sp)
    ld     s9,80(sp)
    ld     s10,88(sp)
    addi   sp,sp,96
    .endm