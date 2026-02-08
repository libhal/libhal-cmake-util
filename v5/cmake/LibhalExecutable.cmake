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

# Executable and demo helpers for libhal projects

# Add a single executable/demo
#
# Usage:
#   libhal_add_executable(my_demo
#       SOURCES demos/my_demo.cpp
#       INCLUDES include/
#       PACKAGES libhal-util libhal-lpc40
#       LINK_LIBRARIES libhal::util libhal::lpc40
#   )
function(libhal_add_executable TARGET_NAME)
    cmake_parse_arguments(ARG 
        "" 
        "" 
        "SOURCES;INCLUDES;PACKAGES;LINK_LIBRARIES" 
        ${ARGN}
    )
    
    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "SOURCES is required for ${TARGET_NAME}")
    endif()
    
    # Create executable
    add_executable(${TARGET_NAME})
    
    # Add sources
    target_sources(${TARGET_NAME} PRIVATE ${ARG_SOURCES})
    
    # Add include directories
    if(ARG_INCLUDES)
        target_include_directories(${TARGET_NAME} PRIVATE ${ARG_INCLUDES})
    endif()
    
    # Find packages
    foreach(PKG IN LISTS ARG_PACKAGES)
        find_package(${PKG} REQUIRED)
    endforeach()
    
    # Link libraries
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET_NAME} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    
    # Apply compile options
    target_link_libraries(${TARGET_NAME} PRIVATE libhal::compile_options)
    
    # Set C++ standard
    target_compile_features(${TARGET_NAME} PRIVATE cxx_std_23)
    
    message(STATUS "Created executable: ${TARGET_NAME}")
endfunction()

# Build multiple demos/executables at once
# Keeps existing monolithic pattern for convenience
#
# Usage:
#   libhal_build_demos(
#       DEMOS demo1 demo2 demo3
#       SOURCES src/common.cpp        # Optional shared sources
#       INCLUDES include/              # Optional include directories
#       PACKAGES libhal-util libhal-lpc40
#       LINK_LIBRARIES libhal::util libhal::lpc40
#   )
#
# This will look for demos/demo1.cpp, demos/demo2.cpp, etc.
function(libhal_build_demos)
    cmake_parse_arguments(ARG 
        "" 
        "" 
        "DEMOS;SOURCES;INCLUDES;PACKAGES;LINK_LIBRARIES" 
        ${ARGN}
    )
    
    if(NOT ARG_DEMOS)
        message(FATAL_ERROR "DEMOS list is required")
    endif()
    
    # Find packages once for all demos
    foreach(PKG IN LISTS ARG_PACKAGES)
        find_package(${PKG} REQUIRED)
    endforeach()
    
    message(STATUS "Building demos:")
    
    # Create each demo
    foreach(DEMO_NAME IN LISTS ARG_DEMOS)
        set(DEMO_FILE "demos/${DEMO_NAME}.cpp")
        
        # Check if demo file exists
        if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${DEMO_FILE}")
            message(WARNING "Demo file not found: ${DEMO_FILE}, skipping...")
            continue()
        endif()
        
        # Build the demo sources list
        set(DEMO_SOURCES ${DEMO_FILE})
        if(ARG_SOURCES)
            list(APPEND DEMO_SOURCES ${ARG_SOURCES})
        endif()
        
        # Create the demo using the granular function
        libhal_add_executable(${DEMO_NAME}
            SOURCES ${DEMO_SOURCES}
            INCLUDES ${ARG_INCLUDES}
            LINK_LIBRARIES ${ARG_LINK_LIBRARIES}
        )
        
        message(STATUS "  - ${DEMO_NAME}")
    endforeach()
endfunction()
