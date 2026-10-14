# Copyright 2026 Khalil Estell and the libhal contributors
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


# Compile checks: code that must fail to compile, verified with Clang's
# -verify mode. See libhal_add_compile_checks().

set(LIBHAL_VERIFY_LAUNCHER "${CMAKE_CURRENT_LIST_DIR}/LibhalVerifyLauncher.cmake"
    CACHE INTERNAL "Compiler launcher that adds Clang's -verify mode")

# Adds an object library, <TARGET_NAME>_compile_checks, that compiles each
# file in FILES with Clang's -verify mode. Each file marks the diagnostics
# it must produce; `@+1` points at the next line, which keeps each
# expectation on its own line where clang-format won't move it:
#
#   // expected-error@+1 {{is returned}}
#   return sensor(bus);
#
# The build fails when an expected diagnostic is missing or an unexpected
# one appears, so a case that stops failing (or a known gap that starts
# being caught) shows up as a build error. Notes are not checked.
#
# Files compile with LIBHAL_CXX_FLAGS (warnings are errors, so lifetime
# findings are written as expected-error) and link TARGET_NAME plus
# LINK_LIBRARIES. Clang skips its lifetime analysis once a file has a hard
# error, so keep type-system rejections (deleted functions, consteval) and
# lifetime analysis findings in separate files. A file that expects no
# diagnostics must say so with `// expected-no-diagnostics`.
#
# Needs Clang 23+ (lifetime analysis); does nothing with other compilers.
function(libhal_add_compile_checks TARGET_NAME)
    cmake_parse_arguments(ARG "" "" "FILES;LINK_LIBRARIES" ${ARGN})

    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "❌ Target '${TARGET_NAME}' does not exist")
    endif()
    if(NOT ARG_FILES)
        message(FATAL_ERROR "❌ libhal_add_compile_checks() needs FILES")
    endif()

    if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
       CMAKE_CXX_COMPILER_VERSION VERSION_LESS "23")
        message(STATUS "⏭️ Skipping compile checks for ${TARGET_NAME} "
                       "(needs Clang 23+)")
        return()
    endif()

    set(CHECKS_TARGET "${TARGET_NAME}_compile_checks")
    add_library(${CHECKS_TARGET} OBJECT ${ARG_FILES})
    target_compile_features(${CHECKS_TARGET} PRIVATE cxx_std_23)
    target_compile_options(${CHECKS_TARGET} PRIVATE ${LIBHAL_CXX_FLAGS})
    target_link_libraries(${CHECKS_TARGET} PRIVATE
        ${TARGET_NAME} ${ARG_LINK_LIBRARIES})
    set_target_properties(${CHECKS_TARGET} PROPERTIES
        # The files contain errors on purpose.
        CXX_CLANG_TIDY ""
        # -verify goes through a launcher because a launcher only wraps the
        # compile step. As a compile option it would also reach the module
        # dependency scanner, which doesn't see the expected-* comments and
        # fails.
        CXX_COMPILER_LAUNCHER
            "${CMAKE_COMMAND};-P;${LIBHAL_VERIFY_LAUNCHER};--")

    message(STATUS "🔍 Added compile checks for ${TARGET_NAME}")
endfunction()
