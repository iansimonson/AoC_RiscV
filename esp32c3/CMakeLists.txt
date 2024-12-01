# The following five lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.16)

set(AOC_YEAR "2024" CACHE STRING "Year to compile against to reduce memory usage")
add_compile_definitions(AOC_YEAR="${AOC_YEAR}" AOC_INCLUDE_DAYS="days/${AOC_YEAR}/include_days.h")

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(aoc_esp32c3)
