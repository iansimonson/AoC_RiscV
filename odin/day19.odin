package solve

import "core:os"
import "core:strings"
import "core:fmt"
import "core:slice"

main :: proc() {
    data, _ := os.read_entire_file("./input19.txt")

    p1 := part1(data)
    p2 := part2(data)

    fmt.printfln("Part 1: %v", p1)
    fmt.printfln("Part 2: %v", p2)
}

Stripe_Map :: map[u8][dynamic]string
Cache :: map[string]bool
Count_Cache :: map[string]int

part1 :: proc(data: []u8) -> (result: int) {
    newline := strings.index_byte(string(data), '\n')
    bits := string(data[:newline])
    stripes := strings.split(bits, ", ")
    m: Stripe_Map
    for s in stripes {
        d := m[s[0]] or_else {}
        append(&d, s)
        m[s[0]] = d
    }
    cache: Cache

    recurse :: proc(pattern: string, stripes: Stripe_Map, cache: ^Cache) -> bool {
        if len(pattern) == 0 {
            return true
        }
        if pattern in cache {
            return cache[pattern]
        }

        key := pattern[0]
        possible_stripes := stripes[key]
        for ps in possible_stripes {
            if strings.has_prefix(pattern, ps) {
                result := recurse(pattern[len(ps):], stripes, cache)
                if result {
                    cache[pattern] = true
                    return true
                }
            }
        }
        cache[pattern] = false
        return false
    }

    patterns := string(data[newline+2:])
    for pattern in strings.split_lines_iterator(&patterns) {
        result += int(recurse(pattern, m, &cache))
    }

    return
}

part2 :: proc(data: []u8) -> (result: int) {
    newline := strings.index_byte(string(data), '\n')
    bits := string(data[:newline])
    stripes := strings.split(bits, ", ")
    m: Stripe_Map
    for s in stripes {
        d := m[s[0]] or_else {}
        append(&d, s)
        m[s[0]] = d
    }
    cache: Count_Cache

    recurse :: proc(pattern: string, stripes: Stripe_Map, cache: ^Count_Cache) -> int {
        if len(pattern) == 0 {
            return 1
        }
        if pattern in cache {
            return cache[pattern]
        } else {
            cache[pattern] = 0
        }

        key := pattern[0]
        possible_stripes := stripes[key]
        for ps in possible_stripes {
            if strings.has_prefix(pattern, ps) {
                ways := recurse(pattern[len(ps):], stripes, cache)
                cache[pattern] += ways
            }
        }
        return cache[pattern]
    }

    patterns := string(data[newline+2:])
    for pattern in strings.split_lines_iterator(&patterns) {
        result += recurse(pattern, m, &cache)
    }

    return
}

/*
map_clone :: proc(m: Stripe_Map) -> Stripe_Map {
    result := make(Stripe_Map, allocator = context.temp_allocator)
    for k, v in m {
        new_v, _ := slice.clone_to_dynamic(v, context.temp_allocator)
        result[k] = new_v
    }
    return result
}
*/