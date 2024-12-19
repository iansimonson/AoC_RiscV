package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"
import pq "core:container/priority_queue"
import q "core:container/queue"

SIZE :: #config(SIZE, 71)
P1_SIMULATE :: #config(P1SIM, 1024)
Pos :: [2]int

main :: proc() {
    data, _ := os.read_entire_file("./input18.txt")

    p1 := part1(data)
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    grid := make([]u8, (SIZE + 1) * SIZE)
    defer delete(grid)
    slice.fill(grid, '.')
    for y in 0..<SIZE {
        grid[y * (SIZE + 1) + SIZE] = '\n'
    }
    bytes := parse_bytes(data)

    for i in 0..<P1_SIMULATE {
        b := bytes[i]
        idx := b.y * (SIZE + 1) + b.x
        grid[idx] = '#'
    }
    result = shortest_path(grid, SIZE + 1, Pos{0, 0}, Pos{SIZE-1, SIZE-1})
    return
}

part2 :: proc(data: []u8) -> [2]int {
    grid := make([]u8, (SIZE + 1) * (SIZE + 1))
    defer delete(grid)
    slice.fill(grid, '.')
    for y in 0..<SIZE {
        grid[y * (SIZE + 1) + SIZE] = '\n'
    }
    bytes := parse_bytes(data)

    for i in 0..<P1_SIMULATE { // we know from p1 there's at least P1_SIMULATE before the cutoff
        b := bytes[i]
        idx := b.y * (SIZE + 1) + b.x
        grid[idx] = '#'
    }

    for i in P1_SIMULATE..<len(bytes) {
        b := bytes[i]
        idx := b.y * (SIZE + 1) + b.x
        grid[idx] = '#'
        if spans_grid(grid, SIZE + 1, idx) {
            return b
        }
    }
    return {0, 0}

}

parse_bytes :: proc(data: []u8) -> []Pos {
    data := string(data)
    poses := make([dynamic]Pos, 0, 1024)
    for p in strings.split_lines_iterator(&data) {
        if len(p) == 0 do continue

        pos: Pos
        p := p
        pos.x, p = parse_int(p)
        p = p[1:] // skip ','
        pos.y, p = parse_int(p)
        append(&poses, pos)
    }

    return poses[:]
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

Node :: struct {
    pos: int,
    fscore: int,
}

Direction :: enum {
    Up,
    Right,
    Down,
    Left,
}

Inf :: max(int)

shortest_path :: proc(grid: []u8, width: int, start, end: Pos) -> int {
    g_score: map[int]int
    defer delete(g_score)

    came_from: map[int]int
    defer delete(came_from)

    start_idx := start.y * width + start.x
    end_idx := end.y * width + end.x
    g_score[start_idx] = 0

    queue: pq.Priority_Queue(Node)
    pq.init(&queue, proc(a, b: Node) -> bool {
        return a.fscore < b.fscore
    }, proc(q: []Node, i, j: int) {
        q[i], q[j] = q[j], q[i]
    })

    pq.push(&queue, Node{pos = start_idx, fscore = 0})
    offsets := [Direction]int{.Up = -width, .Right = 1, .Down = width, .Left = -1}

    result: int

    for pq.len(queue) > 0 {
        node := pq.pop(&queue)
        if node.pos == end_idx {
            result = g_score[node.pos]
            break
        }

        tentative_gscore := g_score[node.pos] + 1

        for n_offset in offsets {
            neighbor := node.pos + n_offset
            if neighbor < 0 || neighbor >= len(grid) || grid[neighbor] != '.' {
                continue // out of bounds or a wall
            }

            cur_gscore := g_score[neighbor] or_else Inf
            if tentative_gscore < cur_gscore {
                g_score[neighbor] = tentative_gscore
                came_from[neighbor] = node.pos
                neighbor_pos := Pos{neighbor % width, neighbor / width}
                new_fscore := tentative_gscore + abs(neighbor_pos.x - end.x) + abs(neighbor_pos.y - end.y)
                next_node := Node{pos = neighbor, fscore = new_fscore}
                update_or_append(&queue, next_node)
            }
        }
    }

    c := end_idx
    for c != start_idx {
        grid[c] = 'O'
        c = came_from[c]
    }

    return result
}

update_or_append :: proc(queue: ^pq.Priority_Queue(Node), node: Node) {
    updated: bool
    for &el, i in queue.queue {
        if el.pos == node.pos {
            el.fscore = node.fscore
            pq.fix(queue, i)
            updated = true
            break
        }
    }
    if !updated {
        pq.push(queue, node)
    }
}


// checking if walls span the entire width or height of the grid
// assert start is within the grid b/c it's where a byte fell
spans_grid :: proc(grid: []u8, width: int, start: int) -> bool {
    walls_touched: [Direction]bool // top, right, down, left
    visited: map[int]bool
    defer delete(visited)

    span_recurse :: proc(grid: []u8, width: int, wt: ^[Direction]bool, visited: ^map[int]bool, idx: int) {
        idx_pos := [2]int{idx % width, idx / width}
        offsets := [][2]int{{-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1}}
        for offset, i in offsets {
            neighbor := idx_pos + offset
            neighbor_idx := neighbor.y * width + neighbor.x

            if visited[neighbor_idx] { 
                continue
            }

            visited[neighbor_idx] = true

            in_bounds := true
            if neighbor.x < 0 {
                wt[.Left] = true
                in_bounds = false
            } else if neighbor.x >= width - 1 { // account for newline
                wt[.Right] = true
                in_bounds = false
            }
            if neighbor.y < 0 {
                wt[.Up] = true
                in_bounds = false
            } else if neighbor.y >= width - 1 {
                wt[.Down] = true
                in_bounds = false
            }

            if in_bounds && grid[neighbor_idx] == '#' {
                span_recurse(grid, width, wt, visited, neighbor_idx)
            }
        }

    }

    span_recurse(grid, width, &walls_touched, &visited, start)
    return (walls_touched[.Up] && walls_touched[.Down]) || (walls_touched[.Left] && walls_touched[.Right]) || (walls_touched[.Up] && walls_touched[.Left]) || (walls_touched[.Down] && walls_touched[.Right])
}