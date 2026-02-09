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
from conan.tools.files import copy
from conan.tools.layout import basic_layout
from pathlib import Path


required_conan_version = ">=2.0.6"


class LibhalCMakeUtilConan(ConanFile):
    name = "libhal-cmake-util"
    license = "Apache-2.0"
    homepage = "https://github.com/libhal/libhal-cmake-util"
    description = "CMake helper functions and utilities for libhal projects"
    topics = ("cmake", "build-helpers", "libhal", "embedded")
    exports_sources = "cmake/*", "LICENSE"
    no_copy_source = True

    def package_id(self):
        self.info.clear()

    def layout(self):
        basic_layout(self)

    def package(self):
        copy(self, "LICENSE", dst=self.package_folder, src=self.source_folder)
        copy(self, "cmake/*.cmake",
             src=self.source_folder,
             dst=self.package_folder)

    def package_info(self):
        # Add cmake/ directory to builddirs so find_package(LibhalCMakeUtil)
        # works
        cmake_dir = str(Path(self.package_folder) / "cmake")
        self.cpp_info.builddirs = [cmake_dir]
