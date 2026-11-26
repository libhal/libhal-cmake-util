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
option(LIBHAL_ENABLE_CLANG_TIDY "Enable clang-tidy checks" ON)
option(LIBHAL_CLANG_TIDY_FIX "Apply clang-tidy fixes automatically. If enabled, automatically enables clang-tidy." OFF)

# Internal function to set up clang-tidy
# Called by libhal_project_init()
function(libhal_setup_clang_tidy)
    if(CMAKE_CROSSCOMPILING)
        message(STATUS "🔄 Cross-compiling, skipping clang-tidy")
        return()
    endif()

    if(NOT LIBHAL_ENABLE_CLANG_TIDY AND NOT LIBHAL_CLANG_TIDY_FIX)
        message(STATUS "⚠️ Clang-tidy disabled")
        message(STATUS "   To enable, pass -DLIBHAL_ENABLE_CLANG_TIDY=ON to your cmake command")
        message(STATUS "   or add set(LIBHAL_ENABLE_CLANG_TIDY ON) to your CMakeLists.txt")
        return()
    endif()

    find_program(CLANG_TIDY_EXE NAMES clang-tidy)

    if(NOT CLANG_TIDY_EXE)
        message(STATUS "❌ Clang-tidy not found - continuing without it")
        return()
    endif()

    message(STATUS "✅ Clang-tidy found: ${CLANG_TIDY_EXE}")

    # Search upward for .clang-tidy, the same way clang-tidy does. Without a
    # config, clang-tidy 23+ enables no checks and fails with "no checks
    # enabled". This happens for packages built from the Conan cache that
    # don't export their .clang-tidy.
    set(CLANG_TIDY_SEARCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    while(NOT EXISTS "${CLANG_TIDY_SEARCH_DIR}/.clang-tidy")
        get_filename_component(CLANG_TIDY_PARENT_DIR
            "${CLANG_TIDY_SEARCH_DIR}" DIRECTORY)
        if(CLANG_TIDY_PARENT_DIR STREQUAL CLANG_TIDY_SEARCH_DIR)
            message(STATUS "⚠️ No .clang-tidy found, skipping clang-tidy")
            return()
        endif()
        set(CLANG_TIDY_SEARCH_DIR "${CLANG_TIDY_PARENT_DIR}")
    endwhile()

    # Build the clang-tidy command
    set(CLANG_TIDY_CMD "${CLANG_TIDY_EXE}"
        "--config-file=${CLANG_TIDY_SEARCH_DIR}/.clang-tidy")

    # A file that does `import std` hands clang-tidy the declarations of the
    # standard library module, and CMake compiles its sources (libc++'s
    # share/libc++/v1) as ordinary includes, not system headers. With libhal's
    # HeaderFilterRegex of ".*", clang-tidy then reports libc++'s own code,
    # such as `_Exit` (bugprone-reserved-identifier). Exclude the directories
    # of the modules CMake builds from the toolchain's modules.json.
    if(CMAKE_CXX_STDLIB_MODULES_JSON AND EXISTS "${CMAKE_CXX_STDLIB_MODULES_JSON}")
        file(READ "${CMAKE_CXX_STDLIB_MODULES_JSON}" STD_MODULES_JSON)
        cmake_path(GET CMAKE_CXX_STDLIB_MODULES_JSON PARENT_PATH STD_MODULES_JSON_DIR)
        string(JSON STD_MODULE_COUNT LENGTH "${STD_MODULES_JSON}" modules)
        set(STD_MODULE_DIRS "")
        if(STD_MODULE_COUNT GREATER 0)
            math(EXPR STD_MODULE_LAST "${STD_MODULE_COUNT} - 1")
            foreach(STD_MODULE_INDEX RANGE ${STD_MODULE_LAST})
                string(JSON STD_MODULE_SOURCE GET "${STD_MODULES_JSON}"
                    modules ${STD_MODULE_INDEX} source-path)
                cmake_path(ABSOLUTE_PATH STD_MODULE_SOURCE
                    BASE_DIRECTORY "${STD_MODULES_JSON_DIR}" NORMALIZE)
                cmake_path(GET STD_MODULE_SOURCE PARENT_PATH STD_MODULE_DIR)
                # Escape regex characters, such as the "+" in "libc++"
                string(REGEX REPLACE "([][+.*?()^$|\\{}])" "\\\\\\1"
                    STD_MODULE_DIR "${STD_MODULE_DIR}")
                list(APPEND STD_MODULE_DIRS "${STD_MODULE_DIR}")
            endforeach()
        endif()
        list(REMOVE_DUPLICATES STD_MODULE_DIRS)
        if(STD_MODULE_DIRS)
            list(JOIN STD_MODULE_DIRS "|" STD_MODULE_DIRS_REGEX)
            list(APPEND CLANG_TIDY_CMD
                "--exclude-header-filter=^(${STD_MODULE_DIRS_REGEX})/")
        endif()
    endif()

    # Add --fix if requested
    if(LIBHAL_CLANG_TIDY_FIX)
        list(APPEND CLANG_TIDY_CMD "--fix")
        message(STATUS "🛠️ Clang-tidy fix ENABLED. Will apply fixes automatically...")
    endif()

    # Set the CMake variable to enable clang-tidy for all targets
    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_CMD} CACHE STRING "clang-tidy command" FORCE)

    message(STATUS "✅ Clang-tidy enabled!")
    message(STATUS "   To disable, pass -DLIBHAL_ENABLE_CLANG_TIDY=OFF to your cmake command")
    message(STATUS "   or add set(LIBHAL_ENABLE_CLANG_TIDY OFF) to your CMakeLists.txt")
endfunction()
