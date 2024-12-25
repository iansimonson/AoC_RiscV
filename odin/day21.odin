package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"
import "core:strconv"

Pos :: [2]int

main :: proc() {
    data, _ := os.read_entire_file("./input21_ex.txt")

    p1 := part1(data)
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    for code in strings.split_lines_iterator(&data) {
        cur_pos := keypad['A']
        l_shortest := 0
        num, _ := strconv.parse_int(code[:len(code) - 1])
        for c in code {
            fmt.printfln("Moving to %c", c)
            l_shortest += calc_actions(cur_pos, keypad[c])
            cur_pos = keypad[c]
        }
        fmt.println("code", code, "shortest:", l_shortest, "num:", num)
        result += l_shortest * num
    }
    return
}

part2 :: proc(data: []u8) -> (result: int) {
    return

}

keypad := [256][2]int{
    'A' = {0, 0},
    '0' = {-1, 0},
    '1' = {-2, -1},
    '2' = {-1, -1},
    '3' = {0, -1},
    '4' = {-2, -2},
    '5' = {-1, -2},
    '6' = {0, -2},
    '7' = {-2, -3},
    '8' = {-1, -3},
    '9' = {0, -3},
    
    // controller
    '^' = {-1, 0},
    '<' = {-2, 1},
    'v' = {-1, 1},
    '>' = {0, 1},
}

calc_actions :: proc(from_pos, to_pos: [2]int) -> int {
    cur_pos := from_pos
    move_to := to_pos
    md_dir_keypad := move_to - cur_pos
    ctrl1_pos := keypad['A']
    fmt.printfln("%v->%v: md_dir=%v", cur_pos, move_to, md_dir_keypad)
    l_shortest := 0

    if md_dir_keypad == ({}) {
        return 1
    }

    for md_dir_keypad != ({}) {
        ctrl1_next := keypad['A']
        // always want to move up and then left
        // or right and then down to avoid empty square
        iters := 0
        if cur_pos.y == 0 && md_dir_keypad.y < 0 {
            ctrl1_next = keypad['^']
            iters = abs(md_dir_keypad.y)
            md_dir_keypad.y = 0
        } else if md_dir_keypad.x < 0 {
            ctrl1_next = keypad['<']
            iters = abs(md_dir_keypad.x)
            md_dir_keypad.x = 0
        } else if md_dir_keypad.y > 0 {
            ctrl1_next = keypad['v']
            iters = abs(md_dir_keypad.y)
            md_dir_keypad.y = 0
        } else if md_dir_keypad.x > 0 {
            ctrl1_next = keypad['>']
            iters = abs(md_dir_keypad.x)
            md_dir_keypad.x = 0
        } else if md_dir_keypad.y < 0 {
            ctrl1_next = keypad['^']
            iters = abs(md_dir_keypad.y)
            md_dir_keypad.y = 0
        } 

        for i in 0..<iters {
            l_shortest += calc_controller(1, ctrl1_pos, ctrl1_next)
            ctrl1_pos = ctrl1_next
        }
    }
    l_shortest += calc_controller(1, ctrl1_pos, keypad['A'])

    return l_shortest
}

calc_controller :: proc(ctrl: int, from, to: [2]int) -> int {
    dist := to - from
    if dist == 0 {
        fmt.printfln("CTRL%d: adding 1", ctrl)
        return 1
    }

    if ctrl == 2 {
        fmt.printfln("CTRL%d: %v->%v: adding - %v", ctrl, from, to, abs(dist.x) + abs(dist.y) + 1)
        return abs(dist.x) + abs(dist.y) + 1
    }
    
    fmt.printfln("CTRL%d: %v->%v dist: %v", ctrl, from, to, dist)
    l_shortest := 0

    next_ctrl_pos := keypad['A']
    for dist != ({}) {
        next_ctrl_next := keypad['A']
        // always want to move down and left
        // or right then up for controller
        iters := 0
        if from.y == 0 && dist.y > 0 {
            next_ctrl_next = keypad['v']
            iters = abs(dist.y)
            dist.y = 0
        } else if dist.x > 0 {
            next_ctrl_next = keypad['>']
            iters = abs(dist.x)
            dist.x = 0
        } else if dist.x < 0 {
            next_ctrl_next = keypad['<']
            iters = abs(dist.x)
            dist.x = 0
        } else if dist.y > 0 {
            next_ctrl_next = keypad['v']
            iters = abs(dist.y)
            dist.y = 0
        } else if dist.y < 0 {
            next_ctrl_next = keypad['^']
            iters = abs(dist.y)
            dist.y = 0
        } 

        for i in 0..<iters {
            l_shortest += calc_controller(ctrl + 1, next_ctrl_pos, next_ctrl_next)
            next_ctrl_pos = next_ctrl_next
        }
    }
    l_shortest += calc_controller(ctrl + 1, next_ctrl_pos, keypad['A'])
    
    return l_shortest
}