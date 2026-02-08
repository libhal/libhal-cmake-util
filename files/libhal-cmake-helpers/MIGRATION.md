# Migration Guide

This guide helps you transition existing libhal projects to use libhal-cmake-helpers.

## Before & After Comparison

### Before (Manual CMake)

```cmake
cmake_minimum_required(VERSION 4.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_COLOR_DIAGNOSTICS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

project(strong_ptr LANGUAGES CXX)

if(NOT CMAKE_GENERATOR MATCHES "Ninja|Visual Studio")
    message(FATAL_ERROR "C++20 modules require Ninja or Visual Studio generator")
endif()

option(LIBHAL_ENABLE_CLANG_TIDY "Enable clang-tidy checks" OFF)
option(LIBHAL_CLANG_TIDY_FIX "Apply clang-tidy fixes automatically" OFF)

# ... 50 lines of clang-tidy setup ...

add_library(libhal_compile_flags INTERFACE)
target_compile_options(libhal_compile_flags INTERFACE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:
        -g -Werror -Wall -Wextra -Wshadow -fexceptions -fno-rtti
        -Wno-unused-command-line-argument -pedantic>
    $<$<CXX_COMPILER_ID:MSVC>:
        /W4 /WX /EHsc /permissive- /GR->
)

add_library(strong_ptr STATIC)
add_library(strong_ptr::strong_ptr ALIAS strong_ptr)
target_compile_features(strong_ptr PUBLIC cxx_std_23)
target_sources(strong_ptr PUBLIC
    FILE_SET CXX_MODULES
    TYPE CXX_MODULES
    FILES modules/strong_ptr.cppm
)
target_compile_options(strong_ptr PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>: ... >
    $<$<CXX_COMPILER_ID:MSVC>: ... >
)

include(GNUInstallDirs)
install(TARGETS strong_ptr ...)
install(EXPORT strong_ptr_targets ...)

# ... 40 lines of test setup ...
```

### After (With libhal-cmake-helpers)

```cmake
cmake_minimum_required(VERSION 4.0)

# CMake helpers from libhal-cmake-helpers
# Source: https://github.com/libhal/libhal-cmake-helpers
find_package(LibhalBuild REQUIRED)

libhal_project_init(strong_ptr)

libhal_add_library(strong_ptr
    MODULES modules/strong_ptr.cppm
)

target_link_libraries(strong_ptr PRIVATE libhal::compile_options)

libhal_install_library(strong_ptr NAMESPACE libhal)

libhal_add_tests(strong_ptr
    TEST_NAMES enable_from_this strong_ptr mixins weak_ptr
    UTIL_MODULE tests/util.cppm
)
```

**Reduction**: ~175 lines → ~25 lines (85% reduction)

## Step-by-Step Migration

### Step 1: Add Dependency

Update your `conanfile.py` to require libhal-cmake-helpers:

```python
def build_requirements(self):
    self.tool_requires("libhal-cmake-helpers/[>=1.0.0]")
```

### Step 2: Replace Project Setup

**Old:**
```cmake
cmake_minimum_required(VERSION 4.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_COLOR_DIAGNOSTICS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

project(my_lib LANGUAGES CXX)

# Generator check
if(NOT CMAKE_GENERATOR MATCHES "Ninja|Visual Studio")
    message(FATAL_ERROR "...")
endif()

# Clang-tidy setup (50+ lines)
# ...
```

**New:**
```cmake
cmake_minimum_required(VERSION 4.0)

find_package(LibhalBuild REQUIRED)
libhal_project_init(my_lib)
```

### Step 3: Replace Library Creation

**Old:**
```cmake
add_library(my_lib STATIC)
add_library(my_lib::my_lib ALIAS my_lib)
target_compile_features(my_lib PUBLIC cxx_std_23)
target_sources(my_lib PUBLIC
    FILE_SET CXX_MODULES
    TYPE CXX_MODULES
    FILES modules/foo.cppm
)
target_compile_options(my_lib PRIVATE ...)
```

**New (granular):**
```cmake
libhal_add_library(my_lib
    MODULES modules/foo.cppm
)
target_link_libraries(my_lib PRIVATE libhal::compile_options)
```

**New (convenience):**
```cmake
libhal_quick_library(my_lib
    MODULES modules/foo.cppm
    NAMESPACE libhal
)
```

### Step 4: Replace Installation

**Old:**
```cmake
include(GNUInstallDirs)

install(
    TARGETS my_lib
    EXPORT my_lib_targets
    FILE_SET CXX_MODULES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    CXX_MODULES_BMI DESTINATION "${CMAKE_INSTALL_LIBDIR}/bmi"
)

install(
    EXPORT my_lib_targets
    FILE "my_lib-config.cmake"
    NAMESPACE libhal::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/my_lib"
    CXX_MODULES_DIRECTORY "cxx-modules"
)
```

**New:**
```cmake
libhal_install_library(my_lib NAMESPACE libhal)
```

### Step 5: Replace Test Setup

**Old:**
```cmake
if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross compiling, skipping unit test execution")
else()
    include(CTest)
    enable_testing()
    
    find_package(ut REQUIRED)
    
    set(TEST_NAMES foo bar baz)
    
    foreach(TEST_NAME IN LISTS TEST_NAMES)
        set(TEST_TARGET "test_${TEST_NAME}")
        add_executable(${TEST_TARGET})
        target_sources(${TEST_TARGET} PUBLIC
            FILE_SET CXX_MODULES
            TYPE CXX_MODULES
            FILES tests/util.cppm
            PRIVATE tests/${TEST_NAME}.test.cpp
        )
        target_compile_features(${TEST_TARGET} PRIVATE cxx_std_23)
        target_link_libraries(${TEST_TARGET} PRIVATE
            Boost::ut
            my_lib
            libhal_compile_flags
            libhal_asan
        )
        add_test(NAME ${TEST_TARGET} COMMAND ${TEST_TARGET})
    endforeach()
endif()
```

**New:**
```cmake
libhal_add_tests(my_lib
    TEST_NAMES foo bar baz
    UTIL_MODULE tests/util.cppm
)
```

## Migration Strategies

### Strategy 1: All at Once
Replace everything in one commit. Best for small projects.

### Strategy 2: Incremental
1. Add libhal-cmake-helpers dependency
2. Replace project init first
3. Keep old library/test code initially
4. Migrate library creation next
5. Migrate tests last

### Strategy 3: Hybrid Approach
Use granular functions initially, then switch to convenience wrappers once comfortable:

```cmake
# Week 1: Granular approach (similar to old code)
libhal_add_library(my_lib ...)
target_link_libraries(my_lib PRIVATE libhal::compile_options)
libhal_install_library(my_lib)

# Week 2+: Switch to convenience wrapper
libhal_quick_library(my_lib ...)
```

## Common Patterns

### Pattern: Modules + Sources Mixed

**Old:**
```cmake
add_library(my_lib STATIC)
target_sources(my_lib PUBLIC
    FILE_SET CXX_MODULES TYPE CXX_MODULES FILES modules/foo.cppm
    PRIVATE src/impl.cpp
)
```

**New:**
```cmake
libhal_add_library(my_lib
    MODULES modules/foo.cppm
    SOURCES src/impl.cpp
)
```

### Pattern: Custom Compile Definitions

**Old:**
```cmake
target_compile_definitions(my_lib PUBLIC MY_DEFINE=1)
```

**New (same):**
```cmake
libhal_add_library(my_lib ...)
target_compile_definitions(my_lib PUBLIC MY_DEFINE=1)
```

The helpers don't prevent you from using standard CMake commands!

### Pattern: Demo Applications

**Old:**
```cmake
add_executable(demo1)
target_sources(demo1 PRIVATE demos/demo1.cpp)
target_link_libraries(demo1 PRIVATE libhal::util)
# ... repeat for each demo ...
```

**New:**
```cmake
libhal_build_demos(
    DEMOS demo1 demo2 demo3
    PACKAGES libhal-util
    LINK_LIBRARIES libhal::util
)
```

## Troubleshooting

### "LibhalBuild not found"

Make sure you've added to `conanfile.py`:
```python
def build_requirements(self):
    self.tool_requires("libhal-cmake-helpers/[>=1.0.0]")
```

### "libhal::compile_options target not found"

You need to call `libhal_project_init()` first:
```cmake
find_package(LibhalBuild REQUIRED)
libhal_project_init(my_project)  # This creates the interface targets
```

### "I need more control"

You can always drop down to raw CMake! The helpers are opt-in:

```cmake
libhal_project_init(my_lib)  # Only use this for project setup

# Then use standard CMake
add_library(my_lib STATIC)
target_sources(my_lib ...)
# Full control from here
```

### "Compile options not being applied"

Remember to link the interface target:
```cmake
target_link_libraries(my_lib PRIVATE libhal::compile_options)
```

Or use the convenience wrapper which does it automatically:
```cmake
libhal_quick_library(my_lib ...)
```

## Getting Help

- **Documentation**: See [README.md](README.md) for full API reference
- **Examples**: Check the `examples/` directory
- **Issues**: https://github.com/libhal/libhal-cmake-helpers/issues
