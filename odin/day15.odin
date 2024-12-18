package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"

main :: proc() {
    data, _ := os.read_entire_file("./input15.txt")
    p2_data := slice.clone(data)

    p1, p2 := part1(data), part2(p2_data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

Direction :: enum {
    Up,
    Right,
    Down,
    Left,
}

part1 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    grid_str, _ := strings.split_iterator(&data, "\n\n")
    instructions, _ := strings.split_iterator(&data, "\n\n")
    width := strings.index_byte(grid_str, '\n') + 1
    player := strings.index_byte(grid_str, '@')

    grid := transmute([]u8) grid_str
    for instr in instructions {
        switch instr {
        case '<':
            player = update(grid, width, player, .Left)
        case '>':
            player = update(grid, width, player, .Right)
        case '^':
            player = update(grid, width, player, .Up)
        case 'v':
            player = update(grid, width, player, .Down)
        }
    }

    for c, i in grid {
        if c == 'O' {
            x, y := i % width, i / width
            result += 100 * y + x
        }
    }
    
    return
}

part2 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    grid_str, _ := strings.split_iterator(&data, "\n\n")
    instructions, _ := strings.split_iterator(&data, "\n\n")
    width := strings.index_byte(grid_str, '\n') + 1

    wide_grid := make([]u8, 2*len(grid_str))
    for c, i in grid_str {
        switch c {
        case '#':
            wide_grid[2*i] = '#'
            wide_grid[2*i + 1] = '#'
        case 'O':
            wide_grid[2*i] = '['
            wide_grid[2*i + 1] = ']'
        case '.':
            wide_grid[2*i] = '.'
            wide_grid[2*i + 1] = '.'
        case '@':
            wide_grid[2*i] = '@'
            wide_grid[2*i + 1] = '.'
        case '\n':
            wide_grid[2*i] = '\n'
            wide_grid[2*i + 1] = '\n'
        }
    }
    width = 2 * width
    player := strings.index_byte(string(wide_grid), '@')


    for instr, count in instructions {
        switch instr {
        case '<':
            player = update2(wide_grid, width, player, .Left)
        case '>':
            player = update2(wide_grid, width, player, .Right)
        case '^':
            player = update2(wide_grid, width, player, .Up)
        case 'v':
            player = update2(wide_grid, width, player, .Down)
        }
        if count % 100 == 0 {
            free_all(context.temp_allocator)
        }
    }

    for c, i in wide_grid {
        if c == '[' {
            x, y := i % width, i / width
            result += 100 * y + x
        }
    }
    
    return
}

parse_int :: proc(d: string) -> (result: int, rem: string) #no_bounds_check {
    rem = d
    for rem[0] >= '0' && rem[0] <= '9' {
        result *= 10
        result += int(rem[0] - '0')
        rem = rem[1:]
    }
    return
}

update :: proc(grid: []u8, width, cur_pos: int, direction: Direction) -> int {
    offsets := [Direction]int{.Up = -width, .Right = 1, .Down = width, .Left = -1}
    offset := offsets[direction]
    next := cur_pos + offset
    for next >= 0 && next < len(grid) {
        if grid[next] == '.' {
            break // empty space ahead somewhere, move all rocks/player
        } else if grid[next] == 'O' {
            next += offset
        } else if grid[next] == '#' {
            return cur_pos // hit a wall so can't move
        } else {
            fmt.printfln("wtf is this? %c", grid[next])
            assert(false)
        }
    }

    // there was an empty space, so swap
    // each rock in the chain as we walk back to cur pos
    reverse_offset := -1 * offset
    for next != cur_pos {
        grid[next] = grid[next + reverse_offset]
        next = next + reverse_offset
    }
    grid[cur_pos] = '.'
    return cur_pos + offset
}

update2 :: proc(grid: []u8, width, cur_pos: int, direction: Direction) -> int {
    offsets := [Direction]int{.Up = -width, .Right = 1, .Down = width, .Left = -1}
    offset := offsets[direction]
    next := cur_pos + offset


    // simple case, just move space
    if grid[next] == '.' {
        grid[next] = grid[cur_pos]
        grid[cur_pos] = '.'
        return next
    }
    // wall immediately ahead, do nothing
    if grid[next] == '#' {
        return cur_pos
    }
    
    // left and right direction doesn't change anything
    // other than its '[' and ']' not 'O'
    if direction == .Left || direction == .Right {
        for next >= 0 && next < len(grid) {
            if grid[next] == '.' {
                break // empty space ahead somewhere, move all rocks/player
            } else if grid[next] == '[' || grid[next] == ']' {
                next += offset
            } else if grid[next] == '#' {
                return cur_pos // hit a wall so can't move
            } else {
                fmt.printfln("wtf is this? %c", grid[next])
                assert(false)
            }
        }

        // there was an empty space, so swap
        // each rock in the chain as we walk back to cur pos
        reverse_offset := -1 * offset
        for next != cur_pos {
            grid[next] = grid[next + reverse_offset]
            next = next + reverse_offset
        }
        grid[cur_pos] = '.'
        return cur_pos + offset
    }

    // going up and down now we need to figure out if all the rocks can
    // be pushed or not by treeing outwards
    curs, nexts := make([dynamic][2]int, context.temp_allocator), make([dynamic][2]int, context.temp_allocator)
    all_rocks := make([dynamic][2]int, context.temp_allocator)
    if grid[next] == '[' {
        append(&curs, [2]int{next, next+1})
        append(&all_rocks, [2]int{next, next+1})
    } else if grid[next] == ']' {
        append(&curs, [2]int{next-1, next})
        append(&all_rocks, [2]int{next-1, next})
    }

    for len(curs) > 0 {
        clear(&nexts)
        for cur in curs {
            next := cur + offset
            if grid[next.x] == ']' { // going to have two rocks potentially
                append(&nexts, [2]int{next.x - 1, next.x})
                append(&all_rocks, [2]int{next.x - 1, next.x})
            } else if grid[next.x] == '[' {
                assert(grid[next.y] == ']')
                append(&nexts, next)
                append(&all_rocks, next)
            } else if grid[next.x] == '.' { // ok but nothing to add

            } else if grid[next.x] == '#' { // can't push any rocks b/c wall
                return cur_pos
            }

            // no need to check ']' b/c covered above
            if grid[next.y] == '[' { // a second rock
                append(&nexts, [2]int{next.y, next.y + 1})
                append(&all_rocks, [2]int{next.y, next.y + 1})
            } else if grid[next.y] == '.' { // ok but nothing to add

            } else if grid[next.y] == '#' { // can't push any rocks b/c wall
                return cur_pos
            }
        }

        // swap the arrays
        curs, nexts = nexts, curs
    }

    // we _know_ the rocks are ok to move, lets start flipping them forward (reverse iterate)
    # reverse for rock in all_rocks {
        // guaranteed to be empty space if we got here
        next := rock + offset
        grid[next.x], grid[next.y] = '[', ']'
        grid[rock.x], grid[rock.y] = '.', '.'
    }
    grid[next] = '@'
    grid[cur_pos] = '.'
    return next

}
