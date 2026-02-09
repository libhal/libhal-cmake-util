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

# LibhalBuild CMake Configuration
# Main entry point for find_package(LibhalBuild)
# Documentation: https://github.com/libhal/libhal-cmake-helpers

# Include all helper modules
include(${CMAKE_CURRENT_LIST_DIR}/LibhalCompileOptions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalClangTidy.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalLibrary.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalExecutable.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalTesting.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalTerminalColor.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/LibhalBinUtils.cmake)

# Main project initialization function
# This is the only "required" function - handles project-level setup
function(libhal_project_init PROJECT_NAME)
    # Standard CMake setup
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON PARENT_SCOPE)
    set(CMAKE_COLOR_DIAGNOSTICS ON PARENT_SCOPE)
    set(CMAKE_CXX_SCAN_FOR_MODULES ON PARENT_SCOPE)

    project(${PROJECT_NAME} LANGUAGES CXX)

    # Require Ninja or Visual Studio for C++20 modules
    if(NOT CMAKE_GENERATOR MATCHES "Ninja|Visual Studio")
        message(FATAL_ERROR "C++20 modules require Ninja or Visual Studio generator")
    endif()

    # Set up clang-tidy if enabled
    libhal_setup_clang_tidy()

    # Add compile_commands.json copy target
    add_custom_target(copy_compile_commands ALL
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
        DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json
        COMMENT "Copying compile_commands.json to source directory"
    )
endfunction()

message(STATUS "LibhalBuild CMake helpers loaded!")
message(STATUS "  Source: https://github.com/libhal/libhal-cmake-util")
