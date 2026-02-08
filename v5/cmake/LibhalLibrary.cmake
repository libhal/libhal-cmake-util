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

include(GNUInstallDirs)

# Granular function: Create a library with sources and/or modules
#
# Usage:
#   libhal_add_library(my_lib
#       SOURCES src/foo.cpp src/bar.cpp
#       MODULES modules/baz.cppm
#   )
function(libhal_add_library TARGET_NAME)
    cmake_parse_arguments(ARG "" "" "SOURCES;MODULES" ${ARGN})
    
    # Create the library
    add_library(${TARGET_NAME} STATIC)
    add_library(${TARGET_NAME}::${TARGET_NAME} ALIAS ${TARGET_NAME})
    
    # Add sources if provided
    if(ARG_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${ARG_SOURCES})
    endif()
    
    # Add modules if provided
    if(ARG_MODULES)
        target_sources(${TARGET_NAME} PUBLIC
            FILE_SET CXX_MODULES
            TYPE CXX_MODULES
            FILES ${ARG_MODULES}
        )
    endif()
    
    # Set C++23 standard for modules support
    target_compile_features(${TARGET_NAME} PUBLIC cxx_std_23)
    
    message(STATUS "Created library: ${TARGET_NAME}")
endfunction()

# Granular function: Install a library with CMake config
#
# Usage:
#   libhal_install_library(my_lib NAMESPACE libhal)
#   libhal_install_library(my_lib)  # Uses library name as namespace
function(libhal_install_library TARGET_NAME)
    cmake_parse_arguments(ARG "" "NAMESPACE" "" ${ARGN})
    
    # Default namespace is the target name
    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE ${TARGET_NAME})
    endif()
    
    # Install the library and its module files
    install(
        TARGETS ${TARGET_NAME}
        EXPORT ${TARGET_NAME}_targets
        FILE_SET CXX_MODULES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        CXX_MODULES_BMI DESTINATION "${CMAKE_INSTALL_LIBDIR}/bmi"
    )
    
    # Install the CMake config files
    install(
        EXPORT ${TARGET_NAME}_targets
        FILE "${TARGET_NAME}-config.cmake"
        NAMESPACE ${ARG_NAMESPACE}::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}"
        CXX_MODULES_DIRECTORY "cxx-modules"
    )
    
    message(STATUS "Configured install for: ${TARGET_NAME} (namespace: ${ARG_NAMESPACE}::)")
endfunction()

# Convenience function: Create and install a library in one call
#
# Usage:
#   libhal_quick_library(my_lib
#       SOURCES src/foo.cpp
#       MODULES modules/bar.cppm
#       NAMESPACE libhal
#   )
function(libhal_quick_library TARGET_NAME)
    cmake_parse_arguments(ARG "" "NAMESPACE" "SOURCES;MODULES" ${ARGN})
    
    # Create the library
    libhal_add_library(${TARGET_NAME}
        SOURCES ${ARG_SOURCES}
        MODULES ${ARG_MODULES}
    )
    
    # Auto-apply compile options and asan
    target_link_libraries(${TARGET_NAME} PRIVATE 
        libhal::compile_options
        $<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:libhal::asan>
    )
    
    # Install with namespace
    if(ARG_NAMESPACE)
        libhal_install_library(${TARGET_NAME} NAMESPACE ${ARG_NAMESPACE})
    else()
        libhal_install_library(${TARGET_NAME})
    endif()
endfunction()

# Monolithic convenience function (keeps existing pattern)
# Combines library creation, testing, and installation
#
# Usage:
#   libhal_test_and_make_library(
#       LIBRARY_NAME libhal-actuator
#       SOURCES src/rc_servo.cpp src/drc_v2.cpp
#       TEST_SOURCES tests/rc_servo.test.cpp tests/drc.test.cpp
#       PACKAGES libhal-mock
#       LINK_LIBRARIES libhal::mock
#   )
function(libhal_test_and_make_library)
    cmake_parse_arguments(ARG 
        "" 
        "LIBRARY_NAME" 
        "SOURCES;TEST_SOURCES;PACKAGES;LINK_LIBRARIES" 
        ${ARGN}
    )
    
    if(NOT ARG_LIBRARY_NAME)
        message(FATAL_ERROR "LIBRARY_NAME is required")
    endif()
    
    # Create library
    libhal_add_library(${ARG_LIBRARY_NAME}
        SOURCES ${ARG_SOURCES}
    )
    
    # Apply compile options
    target_link_libraries(${ARG_LIBRARY_NAME} PRIVATE libhal::compile_options)
    
    # Install library
    libhal_install_library(${ARG_LIBRARY_NAME})
    
    # Add tests if provided
    if(ARG_TEST_SOURCES)
        libhal_add_tests(${ARG_LIBRARY_NAME}
            TEST_SOURCES ${ARG_TEST_SOURCES}
            PACKAGES ${ARG_PACKAGES}
            LINK_LIBRARIES ${ARG_LINK_LIBRARIES}
        )
    endif()
endfunction()
