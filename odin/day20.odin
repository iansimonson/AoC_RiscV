package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"

Pos :: [2]int

main :: proc() {
    data, _ := os.read_entire_file("./input20.txt")

    p1 := part1(data)
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    starting_path_length := strings.count(string(data), ".") + 1
    width := strings.index_byte(string(data), '\n') + 1
    start := strings.index_byte(string(data), 'S')
    end := strings.index_byte(string(data), 'E')

    path_lengths := make([]int, len(data))
    slice.fill(path_lengths, -1)
    offsets := []int{-width, 1, width, -1}
    path_lengths[start] = starting_path_length
    
    
    cur_pos := start
    outer: for cur_pos != end {
        for offset in offsets {
            next := cur_pos + offset
            if next < 0 || next >= len(data) || data[next] == '#' {
                continue
            }
            if path_lengths[next] != -1 {
                continue
            }
            path_lengths[next] = path_lengths[cur_pos] - 1
            cur_pos = next
            continue outer
        }
    }

    cur_pos = start
    outer2: for cur_pos != end {
        // check for cheats
        for offset in offsets {
            next := cur_pos + offset
            if next < 0 || next >= len(data) || data[next] == '.' || data[next] == 'E' || data[next] == 'S' {
                continue
            }
            assert(data[next] == '#')
            cheat_end := next + offset
            if cheat_end < 0 || cheat_end >= len(data) {
                continue
            }

            if data[cheat_end] != '.' && data[cheat_end] != 'E' {
                continue
            }

            if (path_lengths[cur_pos] - path_lengths[cheat_end] - 2) >= 100 {
                result += 1
            }
        }

        // move to next space in race
        for offset in offsets {
            next := cur_pos + offset
            if next < 0 || next >= len(data) || data[next] == '#' {
                continue
            }
            if path_lengths[next] >= path_lengths[cur_pos] || path_lengths[next] == -1 {
                continue
            }
            cur_pos = next
            continue outer2
        }

    }

    return
}

part2 :: proc(data: []u8) -> (result: int) {
    starting_path_length := strings.count(string(data), ".") + 1
    width := strings.index_byte(string(data), '\n') + 1
    length := len(data) / width
    start := strings.index_byte(string(data), 'S')
    end := strings.index_byte(string(data), 'E')

    path_lengths := make([]int, len(data))
    slice.fill(path_lengths, -1)
    offsets := []int{-width, 1, width, -1}
    path_lengths[start] = starting_path_length
    
    
    cur_pos := start
    outer: for cur_pos != end {
        for offset in offsets {
            next := cur_pos + offset
            if next < 0 || next >= len(data) || data[next] == '#' {
                continue
            }
            if path_lengths[next] != -1 {
                continue
            }
            path_lengths[next] = path_lengths[cur_pos] - 1
            cur_pos = next
            continue outer
        }
    }


    // walk backwards from end checking all '.'s within a 20 manhattan
    // distance so a 40x40 along the diagonal rhombus grid around each point
    // this is our map of cheat end points, if >= 0 then we've already checked it
    cheats_ending_at := make([]int, len(data))
    slice.fill(cheats_ending_at, -1)
    moving_window: [dynamic][2]int
    for y in -20..=20 {
        for x in -20..=20 {
            if abs(y) + abs(x) > 20 || (x == 0 && y == 0) {
                continue
            }
            append(&moving_window, [2]int{x, y})
        }
    }
    fmt.println("Beginning p2 cheat search")

    outer2: for cur_pos != start {
        cheats_ending_at[cur_pos] = 0
        cur_xy := [2]int{cur_pos % width, cur_pos / width}
        // check for cheats
        for offset in moving_window {
            square := cur_xy + offset
            if square.x < 0 || square.x >= width || square.y < 0 || square.y >= length {
                continue
            }
            square_idx := square.y * width + square.x
            if data[square_idx] != '.' && data[square_idx] != 'E' && data[square_idx] != 'S' {
                continue
            }
            if cheats_ending_at[square_idx] >= 0 {
                continue
            }

            if (path_lengths[square_idx] - path_lengths[cur_pos] - (abs(offset.x) + abs(offset.y))) >= 100 {
                result += 1
                cheats_ending_at[cur_pos] += 1
            }
        }

        // move to next space in race
        for offset in offsets {
            next := cur_pos + offset
            if next < 0 || next >= len(data) || data[next] == '#' {
                continue
            }
            if path_lengths[next] <= path_lengths[cur_pos] || path_lengths[next] == -1 {
                continue
            }
            cur_pos = next
            continue outer2
        }

    }

    return

}

