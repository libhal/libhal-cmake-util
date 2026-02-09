# libhal-cmake-util

CMake helper functions and utilities for libhal projects. Provides convenient
functions for common patterns.

> [NOTE]
> **Using v4?** The v4 API (toolchain injection style) is deprecated. See
> [v4/README.md](v4/README.md) for legacy documentation. Consider migrating
> to v5 for explicit `find_package()` integration and C++20 module support.

## Installation

Via Conan:

```python
def build_requirements(self):
    self.tool_requires("libhal-cmake-util/[^5.0.0]")
```

## Quick Start

```cmake
cmake_minimum_required(VERSION 4.0)

# Find the helpers package
find_package(LibhalCMakeUtil REQUIRED)

# Initialize your project (required)
libhal_project_init(my_library)

# Create a library target named `my_library` with the following source and
# module files.
libhal_add_library(my_library
    SOURCES src/foo.cpp
    MODULES modules/bar.cppm
)

# Apply standard libhal compiler options
libhal_apply_compile_options(my_library)

# Setup library installation info
libhal_install_library(my_library NAMESPACE libhal)

# Add tests
libhal_add_tests(my_library
    TEST_NAMES foo bar baz
    MODULE tests/util.cppm
)
```

## Core Functions

### `libhal_project_init(PROJECT_NAME)`

**Required** - Sets up project-level configuration. This is the only mandatory function.

What it does:

- Calls `project()` with C++ language
- Enables compile_commands.json export
- Checks for Ninja/Visual Studio generator (required for modules)
- Sets up clang-tidy if enabled
- Adds compile_commands.json copy target

```cmake
libhal_project_init(my_project)
```

### Standard Compile Option Functions

After `libhal_project_init()`, these flag attachment files become available:

#### `libhal_apply_compile_options(TARGET_NAME)`

Standard compile flags for libhal projects.

```cmake
libhal_apply_compile_options(my_lib)
```

Flags included:

- GCC/Clang: `-g -Werror -Wall -Wextra -Wshadow -Wpedantic -fexceptions -fno-rtti`
- MSVC: `/W4 /WX /EHsc /permissive- /GR-`

#### `libhal_apply_asan(TARGET_NAME)`

AddressSanitizer support (non-Windows only):

```cmake
libhal_apply_asan(my_lib)
```

This API is safe to use on Windows. Executing it on a Windows machine does
nothing.

This is recommended only for unit and integration tests.

## Library Functions

### `libhal_add_library(TARGET_NAME)`

Creates a static library target with optional sources and modules.

```cmake
libhal_add_library(my_lib
    SOURCES src/foo.cpp src/bar.cpp
    MODULES modules/baz.cppm modules/qux.cppm
)
```

Arguments:

- 1st argument is the library name (my_lib in the above example)
- `SOURCES` - List of .cpp files
- `MODULES` - List of .cppm module files

You may use the target `my_lib` elsewhere in the code with standard CMake commands like:

```cmake
target_compiler_options(my_lib PRIVATE -Wall)
```

### `libhal_install_library(TARGET_NAME)`

Configures library installation with CMake config files.

```cmake
libhal_install_library(my_lib NAMESPACE libhal)
```

Arguments:

- `NAMESPACE` (optional) - Namespace for exported target (default: library name)

## Testing Functions

### `libhal_add_tests(TARGET_NAME)`

Adds unit tests for a library. Supports two modes:

#### Mode 1: Explicit test file list**

```cmake
libhal_add_tests(my_lib
    TEST_SOURCES tests/foo.test.cpp tests/bar.test.cpp
    PACKAGES libhal-mock
    LINK_LIBRARIES libhal::mock
    MODULES tests/util.cppm
)
```

#### Mode 2: Generate filenames from names

```cmake
libhal_add_tests(my_lib
    TEST_NAMES foo bar baz
    MODULES tests/util.cppm
)
```

Looks for `tests/foo.test.cpp`, `tests/bar.test.cpp`, etc.

#### Arguments

Arguments:

- `TEST_SOURCES` - Explicit list of test files
- `TEST_NAMES` - Generate test filenames (tests/NAME.test.cpp)
- `MODULES` - Optional additional modules for tests
- `PACKAGES` - Additional packages to find
- `LINK_LIBRARIES` - Additional libraries to link

## Executable/Demo Functions

### `libhal_add_executable(TARGET_NAME)`

Creates a single executable/app.

```cmake
libhal_add_executable(my_app
    SOURCES apps/my_app.cpp src/common.cpp
    INCLUDES include/
    PACKAGES libhal-util libhal-lpc40
    LINK_LIBRARIES libhal::util libhal::lpc40
)
```

### `libhal_build_apps()`

Builds multiple apps at once.

```cmake
libhal_build_apps(
    APPS app1 app2 app3
    SOURCES src/common.cpp
    INCLUDES include/
    PACKAGES libhal-util libhal-expander
    LINK_LIBRARIES libhal::util libhal::expander
)
```

Looks for `apps/app1.cpp`, `apps/app2.cpp`, etc.

## Firmware Output Functions

For embedded targets, these functions generate additional output files:

### `libhal_create_hex_file_from(TARGET_NAME)`

Creates Intel HEX file from ELF executable.

```cmake
libhal_create_hex_file_from(my_firmware)
libhal_create_hex_file_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/app.hex")
```

Without the `OUTPUT_DIR` parameter, the file will have the same name as the
target but with the extension `.hex`.

### `libhal_create_binary_file_from(TARGET_NAME)`

Creates raw binary file from ELF executable.

```cmake
libhal_create_binary_file_from(my_firmware)
libhal_create_binary_file_from(my_firmware OUTPUT_DIR "${CMAKE_BINARY_DIR}/app.hex")
```

Without the `OUTPUT_DIR` parameter, the file will have the same name as the
target but with the extension `.hex`.

### `libhal_create_disassembly_from(TARGET_NAME)`

Creates disassembly files (.S and .demangled.S).

```cmake
libhal_create_disassembly_from(my_firmware)
```

### `libhal_create_disassembly_with_source_from(TARGET_NAME)`

Creates a disassembly file with source code interleaved (.lst).

```cmake
libhal_create_disassembly_with_source_from(my_firmware)
```

### `libhal_print_size_of(TARGET_NAME)`

Prints size information (text, data, bss sections).

```cmake
libhal_print_size_of(my_firmware)
```

## Clang-tidy

Enable via CMake options:

```bash
# Enable clang-tidy checks
cmake -DLIBHAL_ENABLE_CLANG_TIDY=ON ..

# Enable with automatic fixes
cmake -DLIBHAL_CLANG_TIDY_FIX=ON ..
```

## Complete Examples

### Example 1: C++20 Modules Library (strong_ptr)

```cmake
cmake_minimum_required(VERSION 4.0)
find_package(LibhalBuild REQUIRED)

libhal_project_init(strong_ptr)

# Create library with modules
libhal_add_library(strong_ptr
    MODULES modules/strong_ptr.cppm
)

# Opt-in to compile options
libhal_apply_compile_options(strong_ptr)

# Install
libhal_install_library(strong_ptr NAMESPACE libhal)

# Add tests
libhal_add_tests(strong_ptr
    TEST_NAMES enable_from_this strong_ptr mixins weak_ptr optional_ptr
    MODULE tests/util.cppm
)
```

### Example 2: Demo Applications

```cmake
cmake_minimum_required(VERSION 3.15)
find_package(LibhalBuild REQUIRED)

libhal_project_init(apps)

libhal_build_apps(
    DEMOS
        drc_v2
        mc_x_v2
        rc_servo
    INCLUDES .
    PACKAGES
        libhal-actuator
        libhal-expander
    LINK_LIBRARIES
        libhal::actuator
        libhal::expander
)
```

### Example 3: Full Manual Control

```cmake
cmake_minimum_required(VERSION 4.0)
find_package(LibhalBuild REQUIRED)

# Initialize project
libhal_project_init(my_advanced_lib)

# Create library manually
add_library(my_advanced_lib STATIC)
target_sources(my_advanced_lib PUBLIC
    FILE_SET CXX_MODULES
    TYPE CXX_MODULES
    FILES modules/foo.cppm modules/bar.cppm
    PRIVATE src/impl.cpp
)

# Opt-in to compile options
target_link_libraries(my_advanced_lib PRIVATE LIBHAL_CXX_FLAGS)

# Custom compile definitions
target_compile_definitions(my_advanced_lib PUBLIC MY_CUSTOM_FLAG)

# Install
libhal_install_library(my_advanced_lib NAMESPACE mycompany)
```

## Philosophy

This package provides **granular building blocks with optional convenience wrappers**:

- **Granular functions** - Full control for complex needs
- **Convenience wrappers** - Sensible defaults for common patterns
- **Opt-in compile options** - Via interface targets
- **Explicit, not magical** - Clear what's happening
- **Composable** - Mix and match as needed

## License

Apache-2.0

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
