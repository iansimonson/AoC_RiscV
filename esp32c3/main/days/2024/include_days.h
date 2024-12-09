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
extern void day2_part1(char *input, int len);
extern void day2_part2(char *input, int len);
extern void day3_part1(char *input, int len);
extern void day3_part2(char *input, int len);
extern void day4_part1(char *input, int len);
extern void day4_part2(char *input, int len);
extern void day5_part1(char *input, int len);
extern void day5_part2(char *input, int len);
extern void day6_part1(char *input, int len);
extern void day6_part2(char *input, int len);
extern void day7_part1(char *input, int len);
extern void day7_part2(char *input, int len);
extern void day8_part1(char *input, int len);
extern void day8_part2(char *input, int len);


solve_fn solutions_p1[25] = {
    day1_part1,
    day2_part1,
    day3_part1,
    day4_part1,
    day5_part1,
    day6_part1,
    day7_part1,
    day8_part1,
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
    day2_part2,
    day3_part2,
    day4_part2,
    day5_part2,
    day6_part2,
    day7_part2,
    day8_part2,
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
