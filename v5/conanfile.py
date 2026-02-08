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

from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout
from conan.tools.files import copy
from pathlib import Path


class LibhalCMakeHelpersConan(ConanFile):
    name = "libhal-cmake-util"
    license = "Apache-2.0"
    author = "Khalil Estell and the libhal contributors"
    url = "https://github.com/libhal/libhal-cmake-helpers"
    description = "CMake helper functions and utilities for libhal projects"
    topics = ("cmake", "build-helpers", "libhal", "embedded")
    settings = "os", "compiler", "build_type", "arch"
    exports_sources = "cmake/*", "CMakeLists.txt", "LICENSE"

    def layout(self):
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

        # Also copy license
        copy(self, "LICENSE",
             src=self.source_folder,
             dst=self.package_folder)

    def package_info(self):
        # This is a build-time only package
        self.cpp_info.set_property("cmake_find_mode", "both")
        self.cpp_info.set_property("cmake_file_name", "LibhalBuild")
        BUILD_DIR = str(Path("lib") / "cmake" / "LibhalBuild")
        self.cpp_info.builddirs = [BUILD_DIR]

    def package_id(self):
        # This is a header-only/build-tool package, no binary compatibility
        self.info.clear()
