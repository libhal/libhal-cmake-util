# libhal-cmake-helpers

CMake helper functions and utilities for libhal projects. Provides both granular building blocks and convenient wrapper functions for common patterns.

## Installation

Via Conan:

```bash
conan install libhal-cmake-helpers/1.0.0@
```

## Quick Start

```cmake
cmake_minimum_required(VERSION 4.0)

# Find the helpers package
# Source: https://github.com/libhal/libhal-cmake-helpers
find_package(LibhalBuild REQUIRED)

# Initialize your project (required)
libhal_project_init(my_library)

# Option 1: Use convenience wrapper
libhal_quick_library(my_library
    SOURCES src/foo.cpp src/bar.cpp
    MODULES modules/baz.cppm
    NAMESPACE libhal
)

# Option 2: Granular control
libhal_add_library(my_library
    SOURCES src/foo.cpp
    MODULES modules/bar.cppm
)
target_link_libraries(my_library PRIVATE libhal::compile_options)
libhal_install_library(my_library NAMESPACE libhal)

# Add tests
libhal_add_tests(my_library
    TEST_NAMES foo bar baz
    UTIL_MODULE tests/util.cppm
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
- Creates `libhal::compile_options` and `libhal::asan` interface targets
- Adds compile_commands.json copy target

```cmake
libhal_project_init(my_project)
```

### Interface Targets

After `libhal_project_init()`, these targets are available:

#### `libhal::compile_options`
Standard compile flags for libhal projects. **Opt-in** via linking:

```cmake
target_link_libraries(my_lib PRIVATE libhal::compile_options)
```

Flags included:
- GCC/Clang: `-g -Werror -Wall -Wextra -Wshadow -Wpedantic -fexceptions -fno-rtti`
- MSVC: `/W4 /WX /EHsc /permissive- /GR-`

#### `libhal::asan`
AddressSanitizer support (non-Windows only):

```cmake
target_link_libraries(my_lib PRIVATE libhal::asan)
```

## Library Functions

### Granular Functions

#### `libhal_add_library(TARGET_NAME)`
Creates a static library with optional sources and modules.

```cmake
libhal_add_library(my_lib
    SOURCES src/foo.cpp src/bar.cpp
    MODULES modules/baz.cppm modules/qux.cppm
)
```

Arguments:
- `SOURCES` - List of .cpp files
- `MODULES` - List of .cppm module files

#### `libhal_install_library(TARGET_NAME)`
Configures library installation with CMake config files.

```cmake
libhal_install_library(my_lib NAMESPACE libhal)
```

Arguments:
- `NAMESPACE` (optional) - Namespace for exported target (default: library name)

### Convenience Functions

#### `libhal_quick_library(TARGET_NAME)`
One-shot library creation, configuration, and installation.

```cmake
libhal_quick_library(strong_ptr
    MODULES modules/strong_ptr.cppm
    NAMESPACE libhal
)
```

Automatically applies:
- `libhal::compile_options`
- `libhal::asan` (when not cross-compiling)
- Installs with CMake config

#### `libhal_test_and_make_library()`
Monolithic function combining library and tests (legacy pattern).

```cmake
libhal_test_and_make_library(
    LIBRARY_NAME libhal-actuator
    SOURCES src/rc_servo.cpp src/drc_v2.cpp
    TEST_SOURCES tests/rc_servo.test.cpp tests/drc.test.cpp
    PACKAGES libhal-mock
    LINK_LIBRARIES libhal::mock
)
```

## Testing Functions

### `libhal_add_tests(TARGET_NAME)`

Adds unit tests for a library. Supports two modes:

**Mode 1: Explicit test file list**
```cmake
libhal_add_tests(my_lib
    TEST_SOURCES tests/foo.test.cpp tests/bar.test.cpp
    PACKAGES libhal-mock
    LINK_LIBRARIES libhal::mock
)
```

**Mode 2: Generate filenames from names**
```cmake
libhal_add_tests(my_lib
    TEST_NAMES foo bar baz
    UTIL_MODULE tests/util.cppm
)
```
Looks for `tests/foo.test.cpp`, `tests/bar.test.cpp`, etc.

Arguments:
- `TEST_SOURCES` - Explicit list of test files
- `TEST_NAMES` - Generate test filenames (tests/NAME.test.cpp)
- `UTIL_MODULE` - Optional utility module for tests
- `PACKAGES` - Additional packages to find
- `LINK_LIBRARIES` - Additional libraries to link

## Executable/Demo Functions

### `libhal_add_executable(TARGET_NAME)`

Creates a single executable/demo.

```cmake
libhal_add_executable(my_demo
    SOURCES demos/my_demo.cpp src/common.cpp
    INCLUDES include/
    PACKAGES libhal-util libhal-lpc40
    LINK_LIBRARIES libhal::util libhal::lpc40
)
```

### `libhal_build_demos()`

Builds multiple demos at once.

```cmake
libhal_build_demos(
    DEMOS demo1 demo2 demo3
    SOURCES src/common.cpp
    INCLUDES include/
    PACKAGES libhal-util libhal-expander
    LINK_LIBRARIES libhal::util libhal::expander
)
```

Looks for `demos/demo1.cpp`, `demos/demo2.cpp`, etc.

## Clang-tidy

Enable via CMake options:

```bash
# Enable clang-tidy checks
cmake -DLIBHAL_ENABLE_CLANG_TIDY=ON ..

# Enable with automatic fixes
cmake -DLIBHAL_CLANG_TIDY_FIX=ON ..
```

Or via Conan:

```bash
conan install . -o enable_clang_tidy=True
conan install . -o clang_tidy_fix=True
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
target_link_libraries(strong_ptr PRIVATE libhal::compile_options)

# Install
libhal_install_library(strong_ptr NAMESPACE libhal)

# Add tests
libhal_add_tests(strong_ptr
    TEST_NAMES enable_from_this strong_ptr mixins weak_ptr optional_ptr
    UTIL_MODULE tests/util.cppm
)
```

### Example 2: Traditional Source Library (libhal-actuator)

```cmake
cmake_minimum_required(VERSION 3.15)
find_package(LibhalBuild REQUIRED)

libhal_project_init(libhal-actuator)

# Quick library with auto-install
libhal_quick_library(libhal-actuator
    SOURCES
        src/rc_servo.cpp
        src/smart_servo/rmd/drc_v2.cpp
        src/smart_servo/rmd/mc_x_v2.cpp
)

# Add tests
libhal_add_tests(libhal-actuator
    TEST_SOURCES
        tests/main.test.cpp
        tests/rc_servo.test.cpp
    PACKAGES libhal-mock
    LINK_LIBRARIES libhal::mock
)
```

### Example 3: Demo Applications

```cmake
cmake_minimum_required(VERSION 3.15)
find_package(LibhalBuild REQUIRED)

libhal_project_init(demos)

libhal_build_demos(
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

### Example 4: Full Manual Control

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
target_link_libraries(my_advanced_lib PRIVATE 
    libhal::compile_options
    libhal::asan
)

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
