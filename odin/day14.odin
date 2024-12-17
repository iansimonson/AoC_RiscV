package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:math/linalg"
import "core:math"

WIDTH :: #config(WIDTH, 101)
HEIGHT :: #config(HEIGHT, 103)

MID_COL :: WIDTH / 2
MID_ROW :: HEIGHT / 2

main :: proc() {
    data, _ := os.read_entire_file("./input14.txt")

    p1, p2 := part1(data), part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    quadrants: [4]int
    for line in strings.split_lines_iterator(&data) {
        line := line
        if len(line) == 0 do continue
        point: [2]int
        velocity: [2]int

        eq := strings.index_byte(line, '=')
        line = line[eq+1:]
        point.x, line = parse_int(line)
        assert(line[0] == ',')
        point.y, line = parse_int(line[1:])

        eq = strings.index_byte(line, '=')
        line = line[eq+1:]
        velocity.x, line = parse_int(line)
        assert(line[0] == ',')
        velocity.y, line = parse_int(line[1:])

        point += velocity * 100
        point.x = point.x %% WIDTH
        point.y = point.y %% HEIGHT
        if point.x == MID_COL || point.y == MID_ROW {
            continue // do not count points on the axes
        }
        col_bit := point.x < MID_COL
        row_bit := point.y < MID_ROW
        quadrants[(int(row_bit) << 1) | int(col_bit)] += 1
    }
    result = quadrants.x * quadrants.y * quadrants.z * quadrants.w
    return
}

part2 :: proc(data: []u8) -> (result: int) {
    return
}

parse_int :: proc(d: string) -> (result: int, rem: string) #no_bounds_check {
    rem = d
    neg: bool
    if rem[0] == '-' {
        neg = true
        rem = rem[1:]
    }
    for rem[0] >= '0' && rem[0] <= '9' {
        result *= 10
        result += int(rem[0] - '0')
        rem = rem[1:]
    }
    if neg {
        result *= -1
    }
    return
}
