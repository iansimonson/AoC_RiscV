package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"
import "core:time"

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

Bot :: struct {
    point: [2]int,
    velocity: [2]int,
}

part2 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    quadrants: [4]int
    bots: [dynamic]Bot
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

        append(&bots, Bot{point, velocity})
    }
    for &b in bots {
        b.point += 6343 * b.velocity
        b.point.x %%= WIDTH
        b.point.y %%= HEIGHT
    }
    grid := make([]u8, (WIDTH+1) * (HEIGHT + 1))
    defer delete(grid)
    for i in 6343..<100000 { // I already ran through 6343 frames 10-15 frames / second manually
        print_grid(grid, bots[:]) // BUT LOL my answer was 6355 I could've just ran this manually a few more frames
        for &b in bots {
            b.point += b.velocity
            b.point.x %%= WIDTH
            b.point.y %%= HEIGHT
        }
        for c, start in grid {
            if c == 'X' && many_xs_diag(grid, start) {
                fmt.println("=========")
                fmt.println("TIME:", i, "MAYBE FOUND TREE")
                fmt.println(string(grid))
                fmt.println("==========")
                time.sleep(1 * time.Second)
            }
        }
    }
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

print_grid :: proc(grid: []u8, bots: []Bot) {
    slice.fill(grid, '.')
    for y in 0..<(HEIGHT+1) {
        grid[y * (WIDTH + 1) + WIDTH] = '\n'
    }
    for b in bots {
        grid[b.point.y * (WIDTH+1) + b.point.x] = 'X'
    }
}

many_xs_diag :: proc(grid: []u8, start: int) -> bool {
    offsets := []int{-WIDTH - 1, -WIDTH + 1}
    next := start
    for offset in offsets {
        count: int = 1
        for {
            next += offset
            if next < 0 || grid[next] == '\n' do break
            if grid[next] != 'X' do break
            count += 1
        }
        if count >= 5 do return true
    }
    return false
}