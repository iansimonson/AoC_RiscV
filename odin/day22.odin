package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:mem"

PRUNE :: 16_777_216

main :: proc() {
    data, _ := os.read_entire_file("./input22.txt")

    p1 := part1(data)
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> (result: int) {
    data := string(data)
    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 do continue
        secret_num := strconv.atoi(line)
        for i in 0..<2000 {
            m64 := secret_num << 6
            secret_num ~= m64
            secret_num %= PRUNE
            d64 := secret_num >> 5
            secret_num ~= d64
            secret_num %= PRUNE
            m2048 := secret_num << 11
            secret_num ~= m2048
            secret_num %= PRUNE
        }
        result += secret_num
    }
    return
}

part2 :: proc(data: []u8) -> int {
    start_secrets := strings.split_lines(string(data))
    num_buyers := len(start_secrets)
    codes := make([dynamic][]int, num_buyers)
    changes := make([dynamic][]int, num_buyers)
    m := new([20][20][20][20]int)
    m_new := new([20][20][20][20]bool)
    for &c in codes {
        c = make([]int, 2001)
    }
    for &c in changes {
        c = make([]int, 2001)
    }

    for start_secret, buyer in start_secrets {
        if len(start_secret) == 0 do continue
        
        mem.zero(m_new, size_of(m_new^))
        secret_num := strconv.atoi(start_secret)
        nums := codes[buyer]
        diffs := changes[buyer]
        coords := [4]int{-1, -1, -1, -1}
        nums[0], diffs[0] = secret_num % 10, 0

        for i in 1..=2000 {
            m64 := secret_num << 6
            secret_num ~= m64
            secret_num %= PRUNE
            d64 := secret_num >> 5
            secret_num ~= d64
            secret_num %= PRUNE
            m2048 := secret_num << 11
            secret_num ~= m2048
            secret_num %= PRUNE
            nums[i] = secret_num % 10
            diffs[i] = nums[i] - nums[i-1]
        }
        coords[1] = diffs[0] + 10
        coords[2] = diffs[1] + 10
        coords[3] = diffs[2] + 10
        for i in 3..=2000 {
            coords.xyz = coords.yzw
            coords.w = diffs[i] + 10
            if !m_new[coords.x][coords.y][coords.z][coords.w] {
                m[coords.x][coords.y][coords.z][coords.w] += nums[i]
            }
            m_new[coords.x][coords.y][coords.z][coords.w] = true
        }
    }

    bananas: int
    for x in 0..<20 do for y in 0..<20 do for z in 0..<20 do for w in 0..<20 {
        bananas = max(bananas, m[x][y][z][w])
    }


    return bananas

}

