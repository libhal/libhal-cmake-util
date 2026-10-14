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


# Compiler launcher for libhal_add_compile_checks(). Runs the compile command
# that follows "--" with Clang's -verify mode added:
#
#   cmake -P LibhalVerifyLauncher.cmake -- <compiler> <arguments>...
#
# The compiler's output goes straight to the build log, and the launcher exits
# with the compiler's exit code. With -verify, Clang succeeds only if the file
# produced exactly the diagnostics it expects. It writes no object file when
# those diagnostics include errors, so on success the launcher creates an empty
# one. The build then treats the check as up to date until the file, a header
# it includes (from the dependency file Clang still writes) or an imported
# module changes.

set(LIBHAL_COMPILE_COMMAND)
set(LIBHAL_OBJECT_FILE)
set(LIBHAL_AFTER_SEPARATOR FALSE)
set(LIBHAL_AFTER_OUTPUT_FLAG FALSE)
math(EXPR LIBHAL_LAST_ARGUMENT "${CMAKE_ARGC} - 1")
foreach(LIBHAL_INDEX RANGE ${LIBHAL_LAST_ARGUMENT})
    set(LIBHAL_ARGUMENT "${CMAKE_ARGV${LIBHAL_INDEX}}")
    if(LIBHAL_AFTER_SEPARATOR)
        list(APPEND LIBHAL_COMPILE_COMMAND "${LIBHAL_ARGUMENT}")
        if(LIBHAL_AFTER_OUTPUT_FLAG)
            set(LIBHAL_OBJECT_FILE "${LIBHAL_ARGUMENT}")
        endif()
        if(LIBHAL_ARGUMENT STREQUAL "-o")
            set(LIBHAL_AFTER_OUTPUT_FLAG TRUE)
        else()
            set(LIBHAL_AFTER_OUTPUT_FLAG FALSE)
        endif()
    elseif(LIBHAL_ARGUMENT STREQUAL "--")
        set(LIBHAL_AFTER_SEPARATOR TRUE)
    endif()
endforeach()

if(NOT LIBHAL_COMPILE_COMMAND)
    message(FATAL_ERROR
        "usage: cmake -P LibhalVerifyLauncher.cmake -- <compiler> <arguments>")
endif()

# Check files hold many failing cases, so don't stop at Clang's default limit
# of 20 errors.
execute_process(
    COMMAND ${LIBHAL_COMPILE_COMMAND}
        -Xclang -verify -Xclang -verify-ignore-unexpected=note
        -ferror-limit=0
    RESULT_VARIABLE LIBHAL_RESULT
)

# RESULT_VARIABLE is a message instead of a number if the compiler crashed.
if(NOT LIBHAL_RESULT MATCHES "^[0-9]+$")
    message(STATUS "${LIBHAL_RESULT}")
    set(LIBHAL_RESULT 1)
endif()

# Stand-in object file so a passing check isn't rebuilt until its inputs
# change. It is never linked into anything. Clang leaves an object from an
# earlier pass untouched, so always refresh its timestamp.
if(LIBHAL_RESULT EQUAL 0 AND LIBHAL_OBJECT_FILE)
    file(TOUCH "${LIBHAL_OBJECT_FILE}")
endif()
cmake_language(EXIT ${LIBHAL_RESULT})
