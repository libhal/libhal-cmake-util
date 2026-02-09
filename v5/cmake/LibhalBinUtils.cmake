# Copyright 2024 - 2025 Khalil Estell and the libhal contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Firmware output generation helpers for embedded targets

# Create Intel HEX file from ELF executable
#
# Generates a .hex file suitable for flashing to microcontrollers.
#
# Usage:
#   libhal_create_hex_file_from(my_firmware)
#   libhal_create_hex_file_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/artifacts")
function(libhal_create_hex_file_from TARGET_NAME)
    cmake_parse_arguments(ARG "" "OUTPUT_DIR" "" ${ARGN})

    # Verify target exists
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target '${TARGET_NAME}' does not exist")
    endif()

    # Verify objcopy is available
    if(NOT CMAKE_OBJCOPY)
        message(WARNING "‼️ objcopy not found - cannot generate hex file for ${TARGET_NAME}")
        return()
    endif()

    # Determine output directory
    if(ARG_OUTPUT_DIR)
        set(OUTPUT_PATH "${ARG_OUTPUT_DIR}/${TARGET_NAME}.hex")
    else()
        set(OUTPUT_PATH "$<TARGET_FILE:${TARGET_NAME}>.hex")
    endif()

    # Create hex file using objcopy
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex
            $<TARGET_FILE:${TARGET_NAME}>
            ${OUTPUT_PATH}
        COMMENT "Creating Intel HEX file: ${TARGET_NAME}.hex"
        VERBATIM
    )

    message(STATUS "Will generate Intel HEX file for ${TARGET_NAME}")
endfunction()

# Create binary file from ELF executable
#
# Generates a .bin file (raw binary) suitable for direct flashing.
#
# Usage:
#   libhal_create_binary_file_from(my_firmware)
#   libhal_create_binary_file_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/artifacts")
function(libhal_create_binary_file_from TARGET_NAME)
    cmake_parse_arguments(ARG "" "OUTPUT_DIR" "" ${ARGN})

    # Verify target exists
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target '${TARGET_NAME}' does not exist")
    endif()

    # Verify objcopy is available
    if(NOT CMAKE_OBJCOPY)
        message(WARNING "‼️ objcopy not found - cannot generate binary file for ${TARGET_NAME}")
        return()
    endif()

    # Determine output directory
    if(ARG_OUTPUT_DIR)
        set(OUTPUT_PATH "${ARG_OUTPUT_DIR}/${TARGET_NAME}.bin")
    else()
        set(OUTPUT_PATH "$<TARGET_FILE:${TARGET_NAME}>.bin")
    endif()

    # Create binary file using objcopy
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary
            $<TARGET_FILE:${TARGET_NAME}>
            ${OUTPUT_PATH}
        COMMENT "Creating binary file: ${TARGET_NAME}.bin"
        VERBATIM
    )

    message(STATUS "Will generate binary file for ${TARGET_NAME}")
endfunction()

# Create disassembly files from ELF executable
#
# Generates two disassembly files:
# - .S - raw disassembly
# - .demangled.S - disassembly with demangled C++ symbols
#
# Usage:
#   libhal_create_disassembly_from(my_firmware)
#   libhal_create_disassembly_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/debug")
function(libhal_create_disassembly_from TARGET_NAME)
    cmake_parse_arguments(ARG "" "OUTPUT_DIR" "" ${ARGN})

    # Verify target exists
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target '${TARGET_NAME}' does not exist")
    endif()

    # Verify objdump is available
    if(NOT CMAKE_OBJDUMP)
        message(WARNING "objdump not found - cannot generate disassembly for ${TARGET_NAME}")
        return()
    endif()

    # Determine output directory
    if(ARG_OUTPUT_DIR)
        set(OUTPUT_PATH_RAW "${ARG_OUTPUT_DIR}/${TARGET_NAME}.S")
        set(OUTPUT_PATH_DEMANGLED "${ARG_OUTPUT_DIR}/${TARGET_NAME}.demangled.S")
    else()
        set(OUTPUT_PATH_RAW "$<TARGET_FILE:${TARGET_NAME}>.S")
        set(OUTPUT_PATH_DEMANGLED "$<TARGET_FILE:${TARGET_NAME}>.demangled.S")
    endif()

    # Create raw disassembly file
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -d -s
            $<TARGET_FILE:${TARGET_NAME}>
            > ${OUTPUT_PATH_RAW}
        COMMENT "Creating disassembly: ${TARGET_NAME}.S"
        VERBATIM
    )

    # Create demangled disassembly file
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -d -s --demangle
            $<TARGET_FILE:${TARGET_NAME}>
            > ${OUTPUT_PATH_DEMANGLED}
        COMMENT "Creating demangled disassembly: ${TARGET_NAME}.demangled.S"
        VERBATIM
    )

    message(STATUS "Will generate disassembly files for ${TARGET_NAME}")
endfunction()

# Create disassembly with source code interleaved
#
# Generates a .lst file containing disassembly mixed with original source code.
# This is useful for analyzing how the compiler translated specific code sections.
#
# Usage:
#   libhal_create_disassembly_with_source_from(my_firmware)
#   libhal_create_disassembly_with_source_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/debug")
function(libhal_create_disassembly_with_source_from TARGET_NAME)
    cmake_parse_arguments(ARG "" "OUTPUT_DIR" "" ${ARGN})

    # Verify target exists
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target '${TARGET_NAME}' does not exist")
    endif()

    # Verify objdump is available
    if(NOT CMAKE_OBJDUMP)
        message(WARNING "objdump not found - cannot generate listing for ${TARGET_NAME}")
        return()
    endif()

    # Determine output directory
    if(ARG_OUTPUT_DIR)
        set(OUTPUT_PATH "${ARG_OUTPUT_DIR}/${TARGET_NAME}.lst")
    else()
        set(OUTPUT_PATH "$<TARGET_FILE:${TARGET_NAME}>.lst")
    endif()

    # Create listing file with source and disassembly
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} --all-headers --source --disassemble --demangle
            $<TARGET_FILE:${TARGET_NAME}>
            > ${OUTPUT_PATH}
        COMMENT "Creating source+disassembly listing: ${TARGET_NAME}.lst"
        VERBATIM
    )

    message(STATUS "Will generate source-annotated disassembly for ${TARGET_NAME}")
endfunction()

# Print size information for the executable
#
# Displays text, data, and bss section sizes after building.
# Useful for tracking memory usage on resource-constrained embedded systems.
#
# Usage:
#   libhal_print_size_of(my_firmware)
function(libhal_print_size_of TARGET_NAME)
    # Verify target exists
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target '${TARGET_NAME}' does not exist")
    endif()

    # Verify size utility is available
    if(NOT CMAKE_SIZE_UTIL)
        message(WARNING "size utility not found - cannot print size info for ${TARGET_NAME}")
        return()
    endif()

    # Print executable size after build
    add_custom_command(
        TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND ${CMAKE_SIZE_UTIL} $<TARGET_FILE:${TARGET_NAME}>
        COMMENT "Memory usage for ${TARGET_NAME}:"
        VERBATIM
    )

    message(STATUS "Will print size information for ${TARGET_NAME}")
endfunction()
