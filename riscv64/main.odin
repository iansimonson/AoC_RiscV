package riscv

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:mem"
import "base:runtime"

unimplemented :: proc "c" ([]u8) {
    context = runtime.default_context()
    fmt.println("This day is unimplemented")
}
Solve_Fn :: #type proc "c" ([]u8)

solutions_p1 := [25]Solve_Fn{
    0 = day1_part1,
    1 = day2_part1,
    2 = day3_part1,
    3 = day4_part1,
    4 = day5_part1,
    5..<25 = unimplemented,
}

solutions_p2 := [25]Solve_Fn{
    0 = day1_part2,
    1 = day2_part2,
    2 = day3_part2,
    3 = day4_part2,
    4 = day5_part2,
    5..<25 = unimplemented,
}

main :: proc() {
    fmt.print("Enter day to solve: ")
    buffer: [1024]u8
    read, err := os.read(os.stdin, buffer[:])
    if err != nil {
        fmt.panicf("Got error, exiting. %v", err)
    }
    day, err_conv := strconv.parse_int(string(buffer[:read -1]))
    if !err_conv {
        fmt.println("Couldn't convert %s to a value", buffer[:read -1])
        os.exit(1)
    }
    if day < 1 || day > 25 {
        fmt.println("Day out of range [0, 25]. got %v", day)
        os.exit(1)
    }

    input, read_err := os.read_entire_file(fmt.tprintf("days/2023/input%d.txt", day))
    if !read_err {
        fmt.println("Error reading file")
        os.exit(1)
    }

    fmt.printfln("Solving day %v", day)
    solutions_p1[day - 1](input)
    solutions_p2[day - 1](input)
    fmt.println("Done...")
}


// Odin places slices into registers as a0: data, a1: len
foreign {
    day1_part1 :: proc "c" (input: []u8) ---
    day1_part2 :: proc "c" (input: []u8) ---
    day2_part1 :: proc "c" (input: []u8) ---
    day2_part2 :: proc "c" (input: []u8) ---
    day3_part1 :: proc "c" (input: []u8) ---
    day3_part2 :: proc "c" (input: []u8) ---
    day4_part1 :: proc "c" (input: []u8) ---
    day4_part2 :: proc "c" (input: []u8) ---
    day5_part1 :: proc "c" (input: []u8) ---
    day5_part2 :: proc "c" (input: []u8) ---
}
