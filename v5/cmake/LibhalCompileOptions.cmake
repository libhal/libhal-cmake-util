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

# Define the compile flags as a variable (users can inspect/print)
set(LIBHAL_CXX_FLAGS
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:
        -g -Werror -Wall -Wextra -Wshadow -fexceptions -fno-rtti
        -Wno-unused-command-line-argument -pedantic>
    $<$<CXX_COMPILER_ID:MSVC>:
        /W4 /WX /EHsc /permissive- /GR->
    CACHE INTERNAL "libhal standard compile flags"
)

set(LIBHAL_ASAN_FLAGS
    $<$<AND:$<NOT:$<PLATFORM_ID:Windows>>,$<CXX_COMPILER_ID:GNU,Clang,AppleClang>>:
        -fsanitize=address>
    CACHE INTERNAL "libhal AddressSanitizer flags"
)

# --icf=safe only folds functions the linker can prove are interchangeable
# under all observable program behavior (including that nothing compares
# their addresses for identity), so it carries no correctness risk. This is
# an LLD-only flag: it's gated to Clang/AppleClang because this org's Clang
# toolchain (the `llvm-toolchain` Conan recipe) is the one paired with LLD;
# GCC builds in this org do not necessarily link with LLD and should not
# receive this flag.
set(LIBHAL_ICF_FLAGS
    $<$<CXX_COMPILER_ID:Clang,AppleClang>:
        -Wl,--icf=safe>
    CACHE INTERNAL "libhal linker identical code folding flags (LLD only)"
)

# Convenience function to apply flags without remembering variable names
function(libhal_apply_compile_options TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "❌ Target '${TARGET_NAME}' does not exist")
    endif()

    target_compile_options(${TARGET_NAME} PRIVATE ${LIBHAL_CXX_FLAGS})
    message(STATUS "Applied libhal compile options to ${TARGET_NAME}")
endfunction()

function(libhal_apply_asan TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "❌ Target '${TARGET_NAME}' does not exist")
    endif()

    if(NOT WIN32)
        target_compile_options(${TARGET_NAME} PRIVATE ${LIBHAL_ASAN_FLAGS})
        target_link_options(${TARGET_NAME} PRIVATE ${LIBHAL_ASAN_FLAGS})
        message(STATUS "🛡️ Applied AddressSanitizer to ${TARGET_NAME}")
    else()
        message(STATUS "🔄 AddressSanitizer not supported on Windows - skipping for ${TARGET_NAME}")
    endif()
endfunction()

# Enables linker identical code folding on an executable target. Folds
# functions that compile to identical machine code (a common result of
# template instantiation over structurally equivalent types - for example,
# coroutine/future wrapper types differing only in a pointer-sized template
# parameter) into a single copy, reducing binary size. Safe to call
# regardless of toolchain: on non-Clang compilers this applies no flags.
function(libhal_apply_icf TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "❌ Target '${TARGET_NAME}' does not exist")
    endif()

    target_link_options(${TARGET_NAME} PRIVATE ${LIBHAL_ICF_FLAGS})
    message(STATUS "🔗 Applied identical code folding to ${TARGET_NAME}")
endfunction()