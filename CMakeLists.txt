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

cmake_minimum_required(VERSION 3.15)

project(libhal-cmake-helpers LANGUAGES NONE)

include(GNUInstallDirs)

# Install all CMake modules
install(
    FILES
        cmake/LibhalBuildConfig.cmake
        cmake/LibhalCompileOptions.cmake
        cmake/LibhalLibrary.cmake
        cmake/LibhalExecutable.cmake
        cmake/LibhalTesting.cmake
        cmake/LibhalClangTidy.cmake
    DESTINATION
        ${CMAKE_INSTALL_LIBDIR}/cmake/LibhalBuild
)

# Create a version file
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/LibhalBuildConfigVersion.cmake"
    VERSION 1.0.0
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/LibhalBuildConfigVersion.cmake"
    DESTINATION
        ${CMAKE_INSTALL_LIBDIR}/cmake/LibhalBuild
)
