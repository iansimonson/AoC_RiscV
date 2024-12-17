package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:math/linalg"
import "core:math"

main :: proc() {
    data, _ := os.read_entire_file("./input13.txt")

    p1, p2 := part1(data), part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    for block in strings.split_iterator(&data, "\n\n") {
        block := block
        if len(block) == 0 do continue
        A, B, Prize := parse_block(block)
        presses, valid := solve_if_possible(A, B, Prize)
        if valid {
            result += presses.x * 3 + presses.y
        }
        
    }
    return
}

part2 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    for block in strings.split_iterator(&data, "\n\n") {
        block := block
        if len(block) == 0 do continue
        A, B, Prize := parse_block(block)
        Prize += 10000000000000
        presses, valid := solve_if_possible(A, B, Prize)
        if valid {
            result += presses.x * 3 + presses.y
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

parse_block :: proc(block: string) -> (A, B, Prize: [2]int) {
    block := block
    first_plus := strings.index_byte(block, '+')
    A.x, block = parse_int(block[first_plus+1:])
    next_plus := strings.index_byte(block, '+')
    A.y, block = parse_int(block[next_plus+1:])
    bfirst_plus := strings.index_byte(block, '+')
    B.x, block = parse_int(block[bfirst_plus+1:])
    bnext_plus := strings.index_byte(block, '+')
    B.y, block = parse_int(block[bnext_plus+1:])
    first_eq := strings.index_byte(block, '=')
    Prize.x, block = parse_int(block[first_eq+1:])
    second_eq := strings.index_byte(block, '=')
    Prize.y, block = parse_int(block[second_eq+1:])
    return
}

solve_if_possible :: proc(A, B, Result: [2]int) -> (ks: [2]int, found: bool) {
    mAB := matrix[2, 2]int{
        A.x, B.x,
        A.y, B.y,
    }
    mAR := matrix[2, 2]int {
        A.x, Result.x,
        A.y, Result.y,
    }
    detAB := linalg.determinant(mAB)
    detAR := linalg.determinant(mAR)
    if A.x == 0 || detAB == 0 { 
        return {}, false
    }

    
    ks[1] = detAR / detAB

    ks[0] = (Result.x - B.x * ks[1]) / A.x
    // if we have a solution then ks0_y == ks[0]
    // otherwise they'll be slightly off
    // ks0_y := (Result.y - B.y * ks[1]) / A.y    
    check: [2]int = ks[0] * A + ks[1] * B
    return ks, check == Result
}