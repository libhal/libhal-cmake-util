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

# Test setup helpers for libhal projects

# Add tests for a library
#
# Supports two modes:
# 1. TEST_SOURCES - explicit test file list
# 2. TEST_NAMES - derive filenames from names (tests/NAME.test.cpp)
#
# Usage:
#   libhal_add_tests(my_lib
#       TEST_SOURCES tests/foo.test.cpp tests/bar.test.cpp
#       PACKAGES libhal-mock
#       LINK_LIBRARIES libhal::mock
#   )
#
#   libhal_add_tests(my_lib
#       TEST_NAMES foo bar baz
#       MODULES tests/util.cppm
#       PACKAGES libhal-mock
#   )
# Public macro that enables testing in caller's scope, then delegates to internal function
macro(libhal_add_tests TARGET_NAME)
    # Skip tests when cross-compiling
    if(CMAKE_CROSSCOMPILING)
        message(STATUS "Cross-compiling, skipping tests for ${TARGET_NAME}")
    else()
        # Enable testing in caller's scope (must be in macro, not function)
        include(CTest)
        enable_testing()

        # Delegate to internal function for proper variable scoping
        _libhal_add_tests_impl(${TARGET_NAME} ${ARGN})
    endif()
endmacro()

# Internal function to add tests (keeps variables scoped)
function(_libhal_add_tests_impl TARGET_NAME)
    cmake_parse_arguments(ARG
        ""
        ""
        "TEST_SOURCES;TEST_NAMES;PACKAGES;LINK_LIBRARIES;MODULES"
        ${ARGN}
    )

    message(STATUS "Adding tests for ${TARGET_NAME}")

    # Disable AddressSanitizer on macOS where it is known not to work:
    #
    # - Upstream LLVM/Clang 20 on macOS 26+: the ASan runtime deadlocks during
    #   initialization (spins forever in __asan::AsanInitFromRtl /
    #   StaticSpinMutex::LockSlow before main() is ever reached).
    # - Upstream LLVM/Clang 22+ on macOS 14/15: llvm-toolchain links programs
    #   against its bundled libc++ there, but the ASan runtime is linked
    #   against the system libc++. Both end up in one process, objects from
    #   one are freed by the other, and ASan aborts (e.g. "attempting free on
    #   address which was not malloc()-ed" in std::locale::~locale at exit).
    if(APPLE AND NOT DEFINED CACHE{LIBHAL_ASAN_MACOS_CHECKED})
        set(LIBHAL_ASAN_MACOS_CHECKED TRUE CACHE INTERNAL "")
        execute_process(
            COMMAND sw_vers -productVersion
            OUTPUT_VARIABLE LIBHAL_MACOS_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(LIBHAL_DISABLE_ASAN FALSE CACHE INTERNAL "")
        if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            if(LIBHAL_MACOS_VERSION VERSION_GREATER_EQUAL "26" AND
               CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "20" AND
               CMAKE_CXX_COMPILER_VERSION VERSION_LESS "21")
                set(LIBHAL_ASAN_DISABLE_REASON
                    "AddressSanitizer is known to deadlock during runtime "
                    "initialization on this combination.")
            elseif(LIBHAL_MACOS_VERSION VERSION_GREATER_EQUAL "14" AND
                   LIBHAL_MACOS_VERSION VERSION_LESS "26" AND
                   CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "22")
                set(LIBHAL_ASAN_DISABLE_REASON
                    "the toolchain's bundled libc++ conflicts with the "
                    "system libc++ that the ASan runtime links against.")
            endif()
        endif()
        if(DEFINED LIBHAL_ASAN_DISABLE_REASON)
            set(LIBHAL_DISABLE_ASAN TRUE CACHE INTERNAL "")
            string(JOIN "" LIBHAL_ASAN_DISABLE_REASON
                ${LIBHAL_ASAN_DISABLE_REASON})
            message(WARNING
                "⚠️  Detected macOS ${LIBHAL_MACOS_VERSION} with LLVM/Clang "
                "${CMAKE_CXX_COMPILER_VERSION}: ${LIBHAL_ASAN_DISABLE_REASON} "
                "Disabling ASan for test targets.")
        endif()
    endif()

    option(LIBHAL_GENERATE_DSYM
        "On macOS, run dsymutil on each test executable after linking to \
generate a .dSYM debug info bundle" ON)

    if(APPLE AND LIBHAL_GENERATE_DSYM)
        find_program(DSYMUTIL_EXECUTABLE dsymutil)
        if(NOT DSYMUTIL_EXECUTABLE)
            message(STATUS "dsymutil not found, skipping dSYM generation")
        endif()
    endif()

    # Find boost-ut for testing
    find_package(ut REQUIRED)

    # Determine test list
    set(TEST_LIST)
    if(ARG_TEST_NAMES)
        foreach(NAME IN LISTS ARG_TEST_NAMES)
            list(APPEND TEST_LIST "tests/${NAME}.test.cpp")
        endforeach()
    else()
        message(FATAL_ERROR "❌ Either TEST_SOURCES or TEST_NAMES must be provided")
    endif()

    # Find additional packages if specified
    foreach(PKG IN LISTS ARG_PACKAGES)
        find_package(${PKG} REQUIRED)
    endforeach()

    message(STATUS "LIBHAL: List of Tests to Build:")
    # Create test executable for each test file
    foreach(TEST_FILE IN LISTS TEST_LIST)
        # Extract test name from file path
        get_filename_component(TEST_NAME ${TEST_FILE} NAME_WE)
        string(REPLACE ".test" "" TEST_NAME ${TEST_NAME})
        set(TEST_TARGET "test_${TEST_NAME}")

        # Create test executable
        add_executable(${TEST_TARGET})

        # Add utility module if provided
        if(ARG_MODULES)
            target_sources(${TEST_TARGET} PUBLIC
                FILE_SET CXX_MODULES
                TYPE CXX_MODULES
                FILES ${ARG_MODULES}
                PRIVATE ${TEST_FILE} ${ARG_TEST_SOURCES}
            )
        else()
            target_sources(${TEST_TARGET} PRIVATE
                ${TEST_FILE} ${ARG_TEST_SOURCES})
        endif()

        # Configure test
        target_compile_features(${TEST_TARGET} PRIVATE cxx_std_23)

        # Link against the library under test and dependencies
        target_link_libraries(${TEST_TARGET} PRIVATE
            Boost::ut
            ${TARGET_NAME}
            ${ARG_LINK_LIBRARIES}
        )

        # Add CXX and ASAN Flags
        target_compile_options(${TEST_TARGET} PRIVATE ${LIBHAL_CXX_FLAGS})
        if(NOT LIBHAL_DISABLE_ASAN)
            target_compile_options(${TEST_TARGET} PRIVATE ${LIBHAL_ASAN_FLAGS})
            target_link_options(${TEST_TARGET} PRIVATE ${LIBHAL_ASAN_FLAGS})
        endif()

        # Register with CTest
        add_test(NAME ${TEST_TARGET} COMMAND ${TEST_TARGET})

        if(APPLE AND LIBHAL_GENERATE_DSYM AND DSYMUTIL_EXECUTABLE)
            # dsymutil reads debug info from the linker's merged LTO object.
            # Give each test its own path; Apple's ld writes a fixed lto.o
            # into a shared -object_path_lto directory, so parallel links
            # overwrite each other's object and dsymutil can't find symbols.
            target_link_options(${TEST_TARGET} PRIVATE
                "LINKER:-object_path_lto,${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${TEST_TARGET}.dir/lto.o")
            add_custom_command(TARGET ${TEST_TARGET} POST_BUILD
                COMMAND ${DSYMUTIL_EXECUTABLE} $<TARGET_FILE:${TEST_TARGET}>
                COMMENT "Generating dSYM for ${TEST_TARGET}"
                VERBATIM
            )
        endif()

        message(STATUS "  - ${TEST_TARGET}")
    endforeach()
endfunction()
