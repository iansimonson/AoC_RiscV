#ifndef C2D9C04C_D68F_48AE_B7DA_0E9C7DC8A60A
#define C2D9C04C_D68F_48AE_B7DA_0E9C7DC8A60A
#include <stdio.h>

typedef void (*solve_fn)(char*,int);

static void unimplemented(char *input, int len)
{
    (void) input;
    (void) len;
    printf("This day is unimplemented\n");
}

extern void day1_part1(char *input, int len);
extern void day1_part2(char *input, int len);


solve_fn solutions_p1[25] = {
    day1_part1,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
};

solve_fn solutions_p2[25] = {
    day1_part2,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
};


#endif /* C2D9C04C_D68F_48AE_B7DA_0E9C7DC8A60A */
