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
