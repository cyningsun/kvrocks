# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

cmake_minimum_required(VERSION 3.16)
project(kvrocks
        DESCRIPTION "NoSQL which is based on RocksDB and compatible with the Redis protocol"
        LANGUAGES C CXX)

set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

option(DISABLE_JEMALLOC "disable use of the jemalloc library" OFF)
option(ENABLE_ASAN "enable address sanitizer" OFF)
option(ENABLE_TSAN "enable thread sanitizer" OFF)
option(ENABLE_UBSAN "enable undefined behavior sanitizer" OFF)
option(ASAN_WITH_LSAN "enable leak sanitizer while address sanitizer is enabled" ON)
option(ENABLE_STATIC_LIBSTDCXX "link kvrocks with static library of libstd++ instead of shared library" OFF)
option(ENABLE_LUAJIT "enable use of luaJIT instead of lua" ON)
option(ENABLE_OPENSSL "enable openssl to support tls connection" OFF)
option(ENABLE_LTO "enable link-time optimization" ON)
set(SYMBOLIZE_BACKEND "" CACHE STRING "symbolization backend library for cpptrace (libbacktrace, libdwarf, or empty)")
set(PORTABLE 0 CACHE STRING "build a portable binary (disable arch-specific optimizations)")
option(ENABLE_NEW_ENCODING "enable new encoding (#1033) for storing 64bit size and expire time in milliseconds" ON)

# to save build time in debug mode
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(ENABLE_LTO OFF)
endif()

if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 11)
        message(FATAL_ERROR "It is expected to build kvrocks with GCC 11 or above")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 12)
        message(FATAL_ERROR "It is expected to build kvrocks with Clang 12 or above")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 13)
        message(FATAL_ERROR "It is expected to build kvrocks with Xcode toolchains 13 or above")
    endif()
else()
    message(WARNING "The compiler you are currently using is not officially supported,
        so you can try switching to GCC>=11 or Clang>=12 if you encounter problems")
endif()

if(CMAKE_GENERATOR STREQUAL "Ninja")
    set(MAKE_COMMAND make)
    set(NINJA_MAKE_JOBS 4 CACHE STRING "specify concurrent level while ninja calling make")
    set(NINJA_MAKE_JOBS_FLAG -j${NINJA_MAKE_JOBS})
else()
    set(MAKE_COMMAND $(MAKE))
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 检测 C++20 协程支持
include(CheckCXXCompilerFlag)
check_cxx_compiler_flag("-fcoroutines" COMPILER_SUPPORTS_COROUTINES)

if(COMPILER_SUPPORTS_COROUTINES)
  message(STATUS "Compiler supports C++20 coroutines")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines")
else()
  message(WARNING "Compiler does not support C++20 coroutines")
endif()

# 架构特定优化
include(CheckCCompilerFlag)

# ARM64/AArch64 架构
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64|AARCH64")
  CHECK_C_COMPILER_FLAG("-march=armv8-a+crc+crypto" HAS_ARMV8_CRC)
  if(HAS_ARMV8_CRC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8-a+crc+crypto -Wno-unused-function")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a+crc+crypto -Wno-unused-function")
    message(STATUS "Building for ARM64 with CRC and crypto extensions")
  else()
    message(STATUS "Building for ARM64 without specific instruction set flags")
  endif()
endif()

# x86_64 架构
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64")
  if(NOT PORTABLE)
    # 非便携式构建：为当前 CPU 优化
    if(MSVC)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:AVX2")
      message(STATUS "Building for x86_64 with AVX2 (MSVC)")
    else()
      # 使用 -mavx2 而不是 -march=native，以更好地控制指令集
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx2")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mavx2")
      message(STATUS "Building for x86_64 with AVX2")
    endif()
  else()
    message(STATUS "Building portable x86_64 binary without architecture-specific optimizations")
  endif()
endif()

set(DEPS_FETCH_PROXY "" CACHE STRING
    "a template URL to proxy the traffic for fetching dependencies,
     e.g. with DEPS_FETCH_PROXY = https://some-proxy/,
     https://example/some-dep.zip -> https://some-proxy/https://example/some-dep.zip")
set(DEPS_FETCH_DIR "" CACHE PATH
    "if specified, dependencies will be downloaded into this directory first,
     and reused in subsequent builds")

if(ENABLE_ASAN AND ENABLE_TSAN)
    message(FATAL_ERROR "ASan and TSan cannot be used at the same time")
endif()

if((ENABLE_ASAN OR ENABLE_TSAN) AND (NOT DISABLE_JEMALLOC))
    message(FATAL_ERROR "ASan/TSan does not work well with JeMalloc")
endif()

if(ENABLE_ASAN)
    if(ASAN_WITH_LSAN)
        if((CMAKE_CXX_COMPILER_ID STREQUAL "GNU") AND (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5"))
            message(FATAL_ERROR "leak sanitizer is not supported until gcc 5")
        endif()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=leak")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=leak")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=leak")
    endif()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()

# Copied from https://github.com/apache/arrow/blob/main/cpp/cmake_modules/san-config.cmake
#
# Flag to enable clang undefined behavior sanitizer
# We explicitly don't enable all of the sanitizer flags:
# - disable 'vptr' because of RTTI issues across shared libraries (?)
# - disable 'alignment' because unaligned access is really OK on Nehalem and we do it
#   all over the place.
# - disable 'function' because it appears to give a false positive
#   (https://github.com/google/sanitizers/issues/911)
# - disable 'float-divide-by-zero' on clang, which considers it UB
#   (https://bugs.llvm.org/show_bug.cgi?id=17000#c1)
#   Note: GCC does not support the 'function' flag.
if(ENABLE_UBSAN)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined -fno-sanitize=alignment,vptr,function,float-divide-by-zero")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=undefined -fno-sanitize=alignment,vptr,function,float-divide-by-zero")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "5.1")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined -fno-sanitize=alignment,vptr")
        set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined -fno-sanitize=alignment,vptr")
    else()
        message(FATAL_ERROR "Cannot use UBSAN without clang or gcc >= 5.1")
    endif()
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=undefined")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-sanitize-recover=all")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-sanitize-recover=all")
endif()
if(ENABLE_TSAN)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=thread")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=thread")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=thread")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# GLIBC < 2.17 should explicitly specify the real-time library when using clock_*
find_library(REALTIME_LIB rt)
if (REALTIME_LIB)
    list(APPEND EXTERNAL_LIBS ${REALTIME_LIB})
endif()

if (CMAKE_HOST_APPLE)
    set(DISABLE_JEMALLOC ON)
    set(ENABLE_LTO OFF)
endif ()

if(NOT DISABLE_JEMALLOC)
    include(cmake/jemalloc.cmake)
    list(APPEND EXTERNAL_LIBS jemalloc)
endif()

set(BUILD_SHARED_LIBS OFF CACHE BOOL "do not build shared libs by default")

if(ENABLE_OPENSSL)
    find_package(OpenSSL REQUIRED)
endif()

# Auto-detect macOS SDK path if not set
if(APPLE AND NOT CMAKE_OSX_SYSROOT)
  execute_process(
    COMMAND xcrun --sdk macosx --show-sdk-path
    OUTPUT_VARIABLE MACOS_SDK_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
    RESULT_VARIABLE result
  )

  if(result EQUAL 0 AND EXISTS "${MACOS_SDK_PATH}")
    set(CMAKE_OSX_SYSROOT "${MACOS_SDK_PATH}" CACHE PATH "macOS SDK path" FORCE)
  else()
    message(FATAL_ERROR "Failed to detect macOS SDK path. "
            "Install Xcode command line tools or set CMAKE_OSX_SYSROOT manually.")
  endif()
endif()

include(cmake/gtest.cmake)
include(cmake/snappy.cmake)
include(cmake/lz4.cmake)
include(cmake/zlib.cmake)
include(cmake/zstd.cmake)
include(cmake/tbb.cmake)
include(cmake/libevent.cmake)
include(cmake/fmt.cmake)
include(cmake/spdlog.cmake)
include(cmake/jsoncons.cmake)
include(cmake/xxhash.cmake)
include(cmake/span.cmake)
include(cmake/trie.cmake)
include(cmake/pegtl.cmake)
include(cmake/rangev3.cmake)
include(cmake/cpptrace.cmake)
include(cmake/fast_float.cmake)
include(cmake/double-conversion.cmake)
include(cmake/gflags.cmake)
include(cmake/glog.cmake)
include(cmake/boost.cmake)
include(cmake/liburing.cmake)
include(cmake/folly.cmake)
include(cmake/rocksdb.cmake)
# NOTE: liboqs is disabled because its internal 'common' target name collides
# with fbthrift's 'common' target. fizz works fine without liboqs (it's optional
# for post-quantum crypto support).
# include(cmake/liboqs.cmake)
include(cmake/fizz.cmake)
include(cmake/wangle.cmake)
include(cmake/mvfst.cmake)
include(cmake/fbthrift.cmake)
include(cmake/cachelib.cmake)

if (ENABLE_LUAJIT)
    include(cmake/luajit.cmake)
else()
    include(cmake/lua.cmake)
endif()

find_package(Threads REQUIRED)

# === Libraries directly used by kvrocks source code ===
# Each cmake/*.cmake exports a self-contained target with proper PUBLIC/INTERFACE
# propagation. Only list libraries whose API is directly #include'd in src/.

# Storage engine (encapsulates snappy/lz4/zstd/zlib as INTERFACE deps)
list(APPEND EXTERNAL_LIBS rocksdb_with_headers)

# Networking
list(APPEND EXTERNAL_LIBS event_with_headers)

# Formatting & logging
list(APPEND EXTERNAL_LIBS fmt)
list(APPEND EXTERNAL_LIBS spdlog)

# Scripting engine
if(ENABLE_LUAJIT)
    list(APPEND EXTERNAL_LIBS luajit)
else()
    list(APPEND EXTERNAL_LIBS lua)
endif()

# TLS (optional)
if(ENABLE_OPENSSL)
    list(APPEND EXTERNAL_LIBS OpenSSL::SSL)
endif()

# Concurrency
list(APPEND EXTERNAL_LIBS tbb)

# Utility / header-only libraries
list(APPEND EXTERNAL_LIBS jsoncons)
list(APPEND EXTERNAL_LIBS Threads::Threads)
list(APPEND EXTERNAL_LIBS Backtrace::backtrace)
list(APPEND EXTERNAL_LIBS xxhash)
list(APPEND EXTERNAL_LIBS span-lite)
list(APPEND EXTERNAL_LIBS tsl_hat_trie)
list(APPEND EXTERNAL_LIBS pegtl)
list(APPEND EXTERNAL_LIBS range-v3)
list(APPEND EXTERNAL_LIBS cpptrace::cpptrace)

# SSD cache (encapsulates cachelib sub-targets + gtest/gmock workaround)
# Transitively provides: folly, fbthrift, glog, gflags, double-conversion,
# Boost::*, dl, aio, liburing, numa via PUBLIC linkage chains.
list(APPEND EXTERNAL_LIBS cachelib_all)

# Add git sha to version.h
find_package(Git REQUIRED)
execute_process(COMMAND sh -c "cat src/VERSION.txt"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} OUTPUT_VARIABLE PROJECT_VERSION)
execute_process(COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} OUTPUT_VARIABLE GIT_SHA)
string(STRIP "${GIT_SHA}" GIT_SHA)
if ((PROJECT_VERSION STREQUAL "unstable") AND (GIT_SHA STREQUAL ""))
	message(WARNING "It is highly recommended to build the unstable branch in a Git repo")
endif ()
configure_file(src/version.h.in ${PROJECT_BINARY_DIR}/version.h)

if ((CMAKE_CXX_COMPILER_ID STREQUAL "GNU") OR (CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
    if (NOT APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc")
    endif()

    if(ENABLE_STATIC_LIBSTDCXX)
        try_compile(FOUND_STATIC_LIBSTDCXX ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/cmake/checks/static_libstdcxx.cc
            LINK_OPTIONS -static-libstdc++ CXX_STANDARD 11)

        if(NOT FOUND_STATIC_LIBSTDCXX)
            message(FATAL_ERROR "cannot find static library of libstdc++, please add ENABLE_STATIC_LIBSTDCXX=OFF to disable")
        endif()

        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++")
    endif()
endif()

# kvrocks objects target
file(GLOB_RECURSE KVROCKS_SRCS src/*.cc)
list(FILTER KVROCKS_SRCS EXCLUDE REGEX src/cli/main.cc)

add_library(kvrocks_objs OBJECT ${KVROCKS_SRCS})

target_include_directories(kvrocks_objs PUBLIC
    src
    src/common
    src/vendor
    ${PROJECT_BINARY_DIR}
)
# Backtrace include directory is now propagated via the Backtrace::backtrace target.
# Note: All external library include directories are now automatically
# propagated through IMPORTED targets and target_link_libraries.

target_compile_features(kvrocks_objs PUBLIC cxx_std_17)
target_compile_options(kvrocks_objs PUBLIC -Wall -Wpedantic -Wsign-compare -Wreturn-type -fno-omit-frame-pointer)
target_compile_options(kvrocks_objs PUBLIC -Werror=unused-parameter)
target_compile_options(kvrocks_objs PUBLIC -Werror=unused-result)
# span_CONFIG_SELECT_SPAN is now set as INTERFACE on span-lite target (cmake/span.cmake)

# disable unused-variable check on GCC < 8 due to the structure bindings
# https://gcc.gnu.org/bugzilla/show_bug.cgi?format=multiple&id=81767
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8)
    target_compile_options(kvrocks_objs PUBLIC -Wno-error=unused-variable)
else()
    target_compile_options(kvrocks_objs PUBLIC -Werror=unused-variable)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(kvrocks_objs PUBLIC -Wno-pedantic)
elseif((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") OR (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"))
    target_compile_options(kvrocks_objs PUBLIC -Wno-gnu-statement-expression)
endif()
target_link_libraries(kvrocks_objs PUBLIC ${EXTERNAL_LIBS})
target_compile_definitions(kvrocks_objs PUBLIC KVROCKS_STORAGE_ENGINE=RocksDB)
if(ENABLE_OPENSSL)
    target_compile_definitions(kvrocks_objs PUBLIC ENABLE_OPENSSL)
endif()
if(ENABLE_NEW_ENCODING)
    target_compile_definitions(kvrocks_objs PUBLIC METADATA_ENCODING_VERSION=1)
else()
    target_compile_definitions(kvrocks_objs PUBLIC METADATA_ENCODING_VERSION=0)
endif()

# disable LTO on GCC <= 9 due to an ICE
if((CMAKE_CXX_COMPILER_ID STREQUAL "GNU") AND (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 10))
    set(ENABLE_LTO OFF)
endif()

if(ENABLE_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_result OUTPUT ipo_output LANGUAGES CXX)

    if(ipo_result)
        set_property(TARGET kvrocks_objs PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(WARNING "LTO is not supported: ${ipo_output}")
    endif()
endif()

# kvrocks main target
add_executable(kvrocks src/cli/main.cc)
target_link_libraries(kvrocks PRIVATE kvrocks_objs)
target_link_options(kvrocks PRIVATE -fno-omit-frame-pointer)
if(ENABLE_LTO AND ipo_result AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_link_options(kvrocks PRIVATE "-fuse-ld=lld")
endif()

# kvrocks2redis sync tool
file(GLOB KVROCKS2REDIS_SRCS utils/kvrocks2redis/*.cc)
add_executable(kvrocks2redis ${KVROCKS2REDIS_SRCS})
target_link_libraries(kvrocks2redis PRIVATE kvrocks_objs)
target_link_options(kvrocks2redis PRIVATE -fno-omit-frame-pointer)
if(ENABLE_LTO AND ipo_result AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_link_options(kvrocks2redis PRIVATE "-fuse-ld=lld")
endif()

# kvrocks unit tests
file(GLOB_RECURSE TESTS_SRCS tests/cppunit/*.cc)
add_executable(unittest ${TESTS_SRCS})
target_include_directories(unittest PRIVATE tests/cppunit)
target_link_libraries(unittest PRIVATE kvrocks_objs gtest_main gmock)
target_link_options(unittest PRIVATE -fno-omit-frame-pointer)

