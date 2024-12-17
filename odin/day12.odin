package solve

import "core:os"
import "core:strings"
import "core:fmt"

main :: proc() {
    data, _ := os.read_entire_file("./input12.txt")

    p1, p2 := part1(data), part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    visited := make([]bool, len(data))
    defer delete(visited)

    grid_width := strings.index_byte(string(data), '\n') + 1
    for c, i in data {
        if visited[i] do continue
        if c == '\n' do continue

        area, perim := flood_fill(data, grid_width, visited, c, i)
        result += area * perim
    }
    return
}

part2 :: proc(data: []u8) -> int {
    return 0
}

flood_fill :: proc(grid: []u8, width: int, visited: []bool, region_type: u8, start_idx: int) -> (area, perim: int) {
    visited[start_idx] = true
    area = 1
    
    neighbor_indicies := []int{start_idx - width, start_idx + 1, start_idx + width, start_idx - 1}
    for neighbor in neighbor_indicies {
        if neighbor < 0 || neighbor >= len(grid) {
            perim += 1 // out of bounds vertically
            continue
        }
        if grid[neighbor] == '\n' || grid[neighbor] != region_type {
            perim += 1
            continue
        }
        if visited[neighbor] {
            continue
        }

        additional_area, additional_perim := flood_fill(grid, width, visited, region_type, neighbor)
        area += additional_area
        perim += additional_perim
    }
    return
}