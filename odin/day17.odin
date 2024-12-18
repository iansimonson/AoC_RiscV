package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"

main :: proc() {
    data, _ := os.read_entire_file("./input17_ex2.txt")

    p1 := strings.clone(part1(data))
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

part1 :: proc(data: []u8) -> string {
    registers = {}
    strings.builder_reset(&output_stream)

    data := string(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.A], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.B], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.C], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:] // data now at instructions
    data, _ = strings.replace_all(data, ",", "")
    data = strings.trim_right_space(data)

    for registers[.PC] < len(data) {
        instr := registers[.PC]
        op := Op(data[instr] - '0')
        operand := data[instr + 1] - '0'
        op_table[op](operand)
    }

    return strings.to_string(output_stream)[1:]
}

part2 :: proc(data: []u8) -> int {
    registers = {}
    strings.builder_reset(&output_stream)
    op_table[.out] = out2

    data := string(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.A], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.B], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:]
    registers[.C], data = parse_int(data)
    data = data[strings.index_byte(data, ':')+2:] // data now at instructions
    data = strings.trim_right_space(data)
    result := strings.clone(data)
    data, _ = strings.replace_all(data, ",", "")
    data = strings.trim_right_space(data)

    a_value: int
    try_registers := registers
    try_registers[.A] = 0
    next := len(data) - 1

    fmt.println("Starting")
    
    outer: for {
        cur_three_bits := -1

        inner: for {
            next_value = data[next]
            cur_three_bits += 1
            fmt.println("Checking for v", next_value - '0', "with", cur_three_bits)
            registers = try_registers
            registers[.A] = a_value
            registers[.A] |= cur_three_bits
            halt = false

            fmt.println(registers)
            
            for registers[.PC] < len(data) {
                instr := registers[.PC]
                op := Op(data[instr] - '0')
                operand := data[instr + 1] - '0'
                op_table[op](operand)
                if halt {
                    fmt.println("halted")
                    continue inner
                }
            }

            fmt.printfln("Found %v with A bits %v", next_value - '0', cur_three_bits)

            a_value <<= 3
            a_value |= cur_three_bits
            cur_three_bits = -1
            next -= 1
            if next < 0 {
                break outer
            }
        }
    }
    return a_value
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

Register :: enum {
    A,
    B,
    C,
    PC,
}

// this is fine we're dealing with registers
// which are global anyway
registers: [Register]int
output_stream: strings.Builder
next_value: u8
halt: bool // set to true if not valid

reg_from_combo :: proc(combo: u8) -> Register {
    return Register(combo & 0x03)
}


Op :: enum {
    adv,
    bxl,
    bst,
    jnz,
    bxc,
    out,
    bdv,
    cdv,
}

adv :: proc(operand: u8) {
    assert(operand != 7)
    power := uint(operand)
    if (operand & 0x4) != 0 {
        power = uint(registers[reg_from_combo(operand)])
    }
    registers[.A] = registers[.A] / (1 << power)
    registers[.PC] += 2
}

bxl :: proc(operand: u8) {
    // something xor 0 is something so don't have to worry about 3 bits
    registers[.B] = registers[.B] ~ int(operand)
    registers[.PC] += 2
}

bst :: proc(operand: u8) {
    assert(operand != 7)
    if (operand & 0x4) != 0 {
        registers[.B] = registers[reg_from_combo(operand)] & 0x7 // % mod 8
    } else {
        registers[.B] = int(operand) // value is 0-3 so no mod needed
    }
    registers[.PC] += 2
}

jnz :: proc(operand: u8) {
    if registers[.A] == 0 {
        registers[.PC] += 2
    } else {
        registers[.PC] = int(operand)
    }
}

bxc :: proc(u8) {
    registers[.B] ~= registers[.C]
    registers[.PC] += 2
}

out :: proc(operand: u8) {
    assert(operand != 7)
    output: int
    if (operand & 0x4) != 0 {
        output = registers[reg_from_combo(operand)] & 0x7
    } else {
        output = int(operand)
    }
    strings.write_byte(&output_stream, ',')
    strings.write_int(&output_stream, output)
    registers[.PC] += 2
}

out2 :: proc(operand: u8) {
    assert(operand != 7)
    output: int
    if (operand & 0x4) != 0 {
        output = registers[reg_from_combo(operand)] & 0x7
    } else {
        output = int(operand)
    }
    fmt.println("Got here - output", output, "regA", registers[.A])
    if (u8(output) + '0') != next_value {
        halt = true
    }
    registers[.PC] += 2
}

bdv :: proc(operand: u8) {
    assert(operand != 7)
    power := uint(operand)
    if (operand & 0x4) != 0 {
        power = uint(registers[reg_from_combo(operand)])
    }
    registers[.B] = registers[.A] / (1 << power)
    registers[.PC] += 2
}

cdv :: proc(operand: u8) {
    assert(operand != 7)
    power := uint(operand)
    if (operand & 0x4) != 0 {
        power = uint(registers[reg_from_combo(operand)])
    }
    registers[.C] = registers[.A] / (1 << power)
    registers[.PC] += 2
}

Op_Proc :: #type proc(operand: u8)

op_table := [Op]Op_Proc{
    .adv = adv,
    .bxl = bxl,
    .bst = bst,
    .jnz = jnz,
    .bxc = bxc,
    .out = out,
    .bdv = bdv,
    .cdv = cdv,
}

