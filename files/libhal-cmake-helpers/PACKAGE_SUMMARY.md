# libhal-cmake-helpers Package Summary

## What's Included

This package provides CMake helpers for the libhal ecosystem with a **granular + convenience wrapper** design philosophy.

### Core Files

1. **CMakeLists.txt** - Main package build file
2. **conanfile.py** - Conan package configuration
3. **LICENSE** - Apache 2.0 license

### CMake Modules (cmake/)

1. **LibhalBuildConfig.cmake** - Main entry point (`find_package(LibhalBuild)`)
2. **LibhalCompileOptions.cmake** - Interface targets for compile flags
3. **LibhalClangTidy.cmake** - Clang-tidy integration
4. **LibhalLibrary.cmake** - Library creation and installation helpers
5. **LibhalTesting.cmake** - Test setup helpers
6. **LibhalExecutable.cmake** - Demo/executable helpers

### Documentation

1. **README.md** - Complete API documentation with examples
2. **MIGRATION.md** - Guide for transitioning existing projects

### Examples (examples/)

1. **strong_ptr_CMakeLists.txt** - C++20 modules library example
2. **libhal-actuator_CMakeLists.txt** - Traditional source library example
3. **demos_CMakeLists.txt** - Demo applications example

## Key Features

### 1. Granular Building Blocks

```cmake
libhal_project_init(my_lib)
libhal_add_library(my_lib MODULES modules/foo.cppm)
target_link_libraries(my_lib PRIVATE libhal::compile_options)
libhal_install_library(my_lib NAMESPACE libhal)
```

### 2. Opt-in Interface Targets

```cmake
# Choose your compile options
target_link_libraries(my_lib PRIVATE libhal::compile_options)
target_link_libraries(my_lib PRIVATE libhal::asan)
```

### 3. Convenience Wrappers

```cmake
# One-line library creation + installation
libhal_quick_library(my_lib
    MODULES modules/foo.cppm
    NAMESPACE libhal
)

# Bulk demo builder
libhal_build_demos(
    DEMOS demo1 demo2 demo3
    PACKAGES libhal-util
    LINK_LIBRARIES libhal::util
)
```

### 4. Legacy Pattern Support

```cmake
# Keeps existing monolithic pattern working
libhal_test_and_make_library(
    LIBRARY_NAME my_lib
    SOURCES src/foo.cpp
    TEST_SOURCES tests/foo.test.cpp
)
```

## Usage in Your Projects

### 1. Add to conanfile.py

```python
def build_requirements(self):
    self.tool_requires("libhal-cmake-helpers/[>=1.0.0]")
```

### 2. Update CMakeLists.txt

**Minimal (175 lines → 25 lines):**
```cmake
cmake_minimum_required(VERSION 4.0)
find_package(LibhalBuild REQUIRED)

libhal_project_init(my_lib)
libhal_quick_library(my_lib MODULES modules/foo.cppm NAMESPACE libhal)
libhal_add_tests(my_lib TEST_NAMES foo bar)
```

**Granular (full control):**
```cmake
cmake_minimum_required(VERSION 4.0)
find_package(LibhalBuild REQUIRED)

libhal_project_init(my_lib)

libhal_add_library(my_lib MODULES modules/foo.cppm)
target_link_libraries(my_lib PRIVATE libhal::compile_options)
libhal_install_library(my_lib NAMESPACE libhal)

libhal_add_tests(my_lib TEST_NAMES foo bar)
```

## Benefits

✅ **Reduces boilerplate** - 85% reduction in CMakeLists.txt size
✅ **Clear and explicit** - Comments show what comes from helpers
✅ **Single source of truth** - Update helpers package, all repos benefit
✅ **Flexible** - Choose granular or convenience based on needs
✅ **Opt-in everything** - Interface targets for compile options
✅ **Backward compatible** - Keeps existing patterns working
✅ **Well documented** - README + MIGRATION guide + examples

## Next Steps

1. **Review** the README.md for complete API documentation
2. **Check** examples/ for real-world usage patterns
3. **Read** MIGRATION.md for transition guidance
4. **Publish** to Conan repository
5. **Update** libhal repos to use the helpers

## Questions?

See README.md or file an issue at:
https://github.com/libhal/libhal-cmake-helpers/issues
