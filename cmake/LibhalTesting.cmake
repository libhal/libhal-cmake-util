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
function(libhal_add_tests TARGET_NAME)
    cmake_parse_arguments(ARG
        ""
        "MODULES"
        "TEST_SOURCES;TEST_NAMES;PACKAGES;LINK_LIBRARIES"
        ${ARGN}
    )

    # Skip tests when cross-compiling
    if(CMAKE_CROSSCOMPILING)
        message(STATUS "Cross-compiling, skipping tests for ${TARGET_NAME}")
        return()
    endif()

    message(STATUS "Adding tests for ${TARGET_NAME}")

    # Enable testing
    include(CTest)
    enable_testing()

    # Find boost-ut for testing
    find_package(ut REQUIRED)

    # Determine test list
    set(TEST_LIST)
    if(ARG_TEST_SOURCES)
        set(TEST_LIST ${ARG_TEST_SOURCES})
    elseif(ARG_TEST_NAMES)
        foreach(NAME IN LISTS ARG_TEST_NAMES)
            list(APPEND TEST_LIST "tests/${NAME}.test.cpp")
        endforeach()
    else()
        message(FATAL_ERROR "Either TEST_SOURCES or TEST_NAMES must be provided")
    endif()

    # Find additional packages if specified
    foreach(PKG IN LISTS ARG_PACKAGES)
        find_package(${PKG} REQUIRED)
    endforeach()

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
                PRIVATE ${TEST_FILE}
            )
        else()
            target_sources(${TEST_TARGET} PRIVATE ${TEST_FILE})
        endif()

        # Configure test
        target_compile_features(${TEST_TARGET} PRIVATE cxx_std_23)

        # Link against the library under test and dependencies
        target_link_libraries(${TEST_TARGET} PRIVATE
            Boost::ut
            ${TARGET_NAME}
            libhal::compile_options
            libhal::asan
            ${ARG_LINK_LIBRARIES}
        )

        # Register with CTest
        add_test(NAME ${TEST_TARGET} COMMAND ${TEST_TARGET})

        message(STATUS "  - ${TEST_TARGET}")
    endforeach()
endfunction()
