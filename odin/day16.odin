package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"
import pq "core:container/priority_queue"
import q "core:container/queue"

main :: proc() {
    data, _ := os.read_entire_file("./input16.txt")

    p1, p2 := part1(data), part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

Direction :: enum {
    Up,
    Right,
    Down,
    Left,
}

Position :: struct {
    x, y: int,
    dir: Direction,
}

Node :: struct {
    using position: Position,
    priority: int, // this is basically fscore
}

Inf :: max(int)

part1 :: proc(data: []u8) -> (result: int) {
    start_pos := strings.index_byte(string(data), 'S')
    end_pos := strings.index_byte(string(data), 'E')
    grid_width := strings.index_byte(string(data), '\n') + 1

    offsets := [Direction][2]int{.Up = {0, -1}, .Right = {1, 0}, .Down = {0, 1}, .Left = {-1, 0}}

    start_x, start_y := start_pos % grid_width, start_pos / grid_width
    // two possible directions for end: Up or Right
    end_x, end_y := end_pos % grid_width, end_pos / grid_width

    g_score: map[Position]int

    queue: pq.Priority_Queue(Node)
    pq.init(&queue, proc(a, b: Node) -> bool {
        return a.priority < b.priority
    }, proc(q: []Node, i, j: int) {
        q[i], q[j] = q[j], q[i]
    })

    start_node := Node{
        x = start_x,
        y = start_y,
        dir = .Right,
        priority = 0,
    }
    pq.push(&queue, start_node)

    for pq.len(queue) > 0 {
        node := pq.pop(&queue)
        if node.x == end_x && node.y == end_y {
            return g_score[Position{node.x, node.y, node.dir}]
        }

        // neighbors are: straight ahead, left turn, or right turn
        { // Forward neighbor

            offset := offsets[node.dir]
            next_node := Node{
                x = node.x + offset.x,
                y = node.y + offset.y,
                dir = node.dir,
            }
            next_pos_idx := next_node.y * grid_width + next_node.x
            next_pos := next_node.position
            if data[next_pos_idx] != '#' {
                cur_gscore := g_score[next_pos] or_else Inf
                new_gscore := g_score[node.position] + 1
                if new_gscore < cur_gscore {
                    g_score[next_pos] = new_gscore
                    new_fscore := new_gscore + abs(next_pos.x - end_x) + abs(next_pos.y - end_y)
                    next_node.priority = new_fscore
                    update_or_append(&queue, next_node)
                }
            }
        }

        { // left turn neighbor
            next_node := node
            next_node.dir = Direction((int(next_node.dir) - 1) %% len(Direction))
            cur_gscore := g_score[next_node.position] or_else Inf
            new_gscore := g_score[node.position] + 1000
            if new_gscore < cur_gscore {
                g_score[next_node.position] = new_gscore
                next_node.priority = new_gscore + abs(next_node.x - end_x) + abs(next_node.y - end_y)
                update_or_append(&queue, next_node)
            }
        }
        { // right turn neighbor
            next_node := node
            next_node.dir = Direction((int(next_node.dir) + 1) %% len(Direction))
            cur_gscore := g_score[next_node.position] or_else Inf
            new_gscore := g_score[node.position] + 1000
            if new_gscore < cur_gscore {
                g_score[next_node.position] = new_gscore
                next_node.priority = new_gscore + abs(next_node.x - end_x) + abs(next_node.y - end_y)
                update_or_append(&queue, next_node)
            }
        }
    }

    return
}

part2 :: proc(data: []u8) -> (result: int) {
    start_pos := strings.index_byte(string(data), 'S')
    end_pos := strings.index_byte(string(data), 'E')
    grid_width := strings.index_byte(string(data), '\n') + 1

    offsets := [Direction][2]int{.Up = {0, -1}, .Right = {1, 0}, .Down = {0, 1}, .Left = {-1, 0}}

    start_x, start_y := start_pos % grid_width, start_pos / grid_width
    // two possible directions for end: Up or Right
    end_x, end_y := end_pos % grid_width, end_pos / grid_width

    g_score: map[Position]int
    came_from: map[Position][dynamic]Position // can have multiple paths

    queue: pq.Priority_Queue(Node)
    pq.init(&queue, proc(a, b: Node) -> bool {
        return a.priority < b.priority
    }, proc(q: []Node, i, j: int) {
        q[i], q[j] = q[j], q[i]
    })

    start_node := Node{
        x = start_x,
        y = start_y,
        dir = .Right,
        priority = 0,
    }
    pq.push(&queue, start_node)

    for pq.len(queue) > 0 {
        node := pq.pop(&queue)
        if node.x == end_x && node.y == end_y {
            continue
        }

        // neighbors are: straight ahead, left turn, or right turn
        { // Forward neighbor

            offset := offsets[node.dir]
            next_node := Node{
                x = node.x + offset.x,
                y = node.y + offset.y,
                dir = node.dir,
            }
            next_pos_idx := next_node.y * grid_width + next_node.x
            next_pos := next_node.position
            if data[next_pos_idx] != '#' {
                cur_gscore := g_score[next_pos] or_else Inf
                new_gscore := g_score[node.position] + 1
                if new_gscore < cur_gscore {
                    g_score[next_pos] = new_gscore
                    new_fscore := new_gscore
                    next_node.priority = new_fscore
                    update_or_append(&queue, next_node)
                    if came_froms, exists := &came_from[next_node]; exists {
                        clear(came_froms)
                        append(came_froms, node.position)
                    } else {
                        came_from[next_node] = [dynamic]Position{node.position}
                    }
                } else if new_gscore == cur_gscore {
                    came_froms := &came_from[next_node]
                    append(came_froms, node.position)
                }
            }
        }

        { // left turn neighbor
            next_node := node
            next_node.dir = Direction((int(next_node.dir) - 1) %% len(Direction))
            cur_gscore := g_score[next_node.position] or_else Inf
            new_gscore := g_score[node.position] + 1000
            if new_gscore < cur_gscore {
                g_score[next_node.position] = new_gscore
                next_node.priority = new_gscore
                update_or_append(&queue, next_node)
                if came_froms, exists := &came_from[next_node]; exists {
                    clear(came_froms)
                    append(came_froms, node.position)
                } else {
                    came_from[next_node] = [dynamic]Position{node.position}
                }
            } else if new_gscore == cur_gscore {
                came_froms := &came_from[next_node]
                append(came_froms, node.position)
            }
        }
        { // right turn neighbor
            next_node := node
            next_node.dir = Direction((int(next_node.dir) + 1) %% len(Direction))
            cur_gscore := g_score[next_node.position] or_else Inf
            new_gscore := g_score[node.position] + 1000
            if new_gscore < cur_gscore {
                g_score[next_node.position] = new_gscore
                next_node.priority = new_gscore
                update_or_append(&queue, next_node)
                if came_froms, exists := &came_from[next_node]; exists {
                    clear(came_froms)
                    append(came_froms, node.position)
                } else {
                    came_from[next_node] = [dynamic]Position{node.position}
                }
            } else if new_gscore == cur_gscore {
                came_froms := &came_from[next_node]
                append(came_froms, node.position)
            }
        }
    }

    gs1 := g_score[Position{end_x, end_y, .Up}] or_else Inf
    gs2 := g_score[Position{end_x, end_y, .Right}] or_else Inf
    if gs1 < gs2 {
        return count_came_from(came_from, [2]int{start_x, start_y}, Position{end_x, end_y, .Up})
    } else if gs2 < gs1 {
        return count_came_from(came_from, [2]int{start_x, start_y}, Position{end_x, end_y, .Right})
    } else {
        return count_came_from(came_from, [2]int{start_x, start_y}, Position{end_x, end_y, .Right}) + count_came_from(came_from, [2]int{start_x, start_y}, Position{end_x, end_y, .Up})
    }
}

update_or_append :: proc(queue: ^pq.Priority_Queue(Node), node: Node) {
    updated: bool
    for &el, i in queue.queue {
        if el.position == node.position {
            el.priority = node.priority
            pq.fix(queue, i)
            updated = true
            break
        }
    }
    if !updated {
        pq.push(queue, node)
    }
}

count_came_from :: proc(came_from: map[Position][dynamic]Position, start: [2]int, goal: Position) -> int {
    visited: map[[2]int]bool
    poss: q.Queue(Position)
    q.append(&poss, goal)
    result: int

    for q.len(poss) != 0 {
        pos := q.pop_front(&poss)
        if !visited[[2]int{pos.x, pos.y}] {
            result += 1
            visited[[2]int{pos.x, pos.y}] = true
        }
        if pos.x == start.x && pos.y == start.y {
            continue
        }
        came_froms := came_from[pos]
        for v in came_froms {
            q.append(&poss, v)
        }
    }
    return result
}