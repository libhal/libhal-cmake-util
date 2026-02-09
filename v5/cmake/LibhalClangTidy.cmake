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

# Clang-tidy integration for libhal projects

# Options for controlling clang-tidy
option(LIBHAL_ENABLE_CLANG_TIDY "Enable clang-tidy checks" OFF)
option(LIBHAL_CLANG_TIDY_FIX "Apply clang-tidy fixes automatically. If enabled, automatically enables clang-tidy." OFF)

# Internal function to set up clang-tidy
# Called by libhal_project_init()
function(libhal_setup_clang_tidy)
    if(CMAKE_CROSSCOMPILING)
        message(STATUS "🔄 Cross-compiling, skipping clang-tidy")
        return()
    endif()

    if(NOT LIBHAL_ENABLE_CLANG_TIDY AND NOT LIBHAL_CLANG_TIDY_FIX)
        message(STATUS "⚠️ Clang-tidy disabled. Use -DLIBHAL_ENABLE_CLANG_TIDY=ON to enable) or try -o '*:enable_clang_tidy=True' on conan packages with that option")
        return()
    endif()

    find_program(CLANG_TIDY_EXE NAMES clang-tidy)

    if(NOT CLANG_TIDY_EXE)
        message(STATUS "❌ Clang-tidy not found - continuing without it")
        return()
    endif()

    message(STATUS "✅ Clang-tidy found: ${CLANG_TIDY_EXE}")

    # Build the clang-tidy command
    set(CLANG_TIDY_CMD "${CLANG_TIDY_EXE}")

    # Look for .clang-tidy file
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy")
        list(APPEND CLANG_TIDY_CMD "--config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy")
    endif()

    # Add --fix if requested
    if(LIBHAL_CLANG_TIDY_FIX)
        list(APPEND CLANG_TIDY_CMD "--fix")
        message(STATUS "🛠️ Clang-tidy will apply fixes automatically")
    endif()

    # Set the CMake variable to enable clang-tidy for all targets
    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_CMD} CACHE STRING "clang-tidy command" FORCE)

    message(STATUS "✅ Clang-tidy enabled!")
endfunction()
