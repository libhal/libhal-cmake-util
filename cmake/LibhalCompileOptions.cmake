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

# Creates interface targets for compile options
# Users can opt-in via: target_link_libraries(my_lib PRIVATE libhal::compile_options)

function(libhal_create_interface_targets)
    # Only create once (in case multiple projects use this)
    if(TARGET libhal::compile_options)
        return()
    endif()

    # Standard compile options for libhal libraries
    add_library(libhal::compile_options INTERFACE IMPORTED GLOBAL)
    target_compile_options(libhal::compile_options INTERFACE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:
            -g
            -Werror
            -Wall
            -Wextra
            -Wshadow
            -Wno-unused-command-line-argument
            -Wpedantic
            -fexceptions
            -fno-rtti
        >
        $<$<CXX_COMPILER_ID:MSVC>:
            /W4
            /WX
            /EHsc
            /permissive-
            /GR-
        >
    )

    # AddressSanitizer support (GCC/Clang on non-Windows only)
    add_library(libhal::asan INTERFACE IMPORTED GLOBAL)
    if(NOT WIN32)
        target_compile_options(libhal::asan INTERFACE
            $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-fsanitize=address>
        )
        target_link_options(libhal::asan INTERFACE
            $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-fsanitize=address>
        )
    endif()

    message(STATUS "Created libhal interface targets:")
    message(STATUS "  - libhal::compile_options (opt-in compile flags)")
    message(STATUS "  - libhal::asan (opt-in AddressSanitizer)")
endfunction()
