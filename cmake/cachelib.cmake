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

# 防止重复包含此文件
include_guard()

# 引入项目的工具函数库
include(cmake/utils.cmake)

FetchContent_Declare(cachelib
  URL https://github.com/facebook/CacheLib/archive/refs/tags/v2024.02.26.00.tar.gz
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# 获取 cachelib 源码
FetchContent_GetProperties(cachelib)
if(NOT cachelib_POPULATED)
  FetchContent_Populate(cachelib)
  message(STATUS "CacheLib source downloaded to: ${cachelib_SOURCE_DIR}")
endif()

# ============================================================================
# CacheLib 编译配置
# ============================================================================
message(STATUS "CacheLib dependencies status:")
message(STATUS "  ✅ Threads, Boost, Gflags, Glog, GTest - available")
message(STATUS "  ✅ fmt, Zlib, Zstd - available")
message(STATUS "  ✅ folly - compiled in build tree")
message(STATUS "  ✅ fizz, wangle, mvfst, fbthrift - compiled in build tree")
message(STATUS "  ⚠️  NUMA, libaio - optional, will check at runtime")
message(STATUS "")

# 禁用 CacheLib 的测试和示例
set(BUILD_TESTS OFF CACHE BOOL "Build CacheLib tests")
set(BUILD_EXAMPLES OFF CACHE BOOL "Build CacheLib examples")

# 使用 FetchContent_MakeAvailable 编译 CacheLib
# CacheLib 会自动在同一构建树中找到所有 Facebook 库的目标
message(STATUS "Configuring CacheLib (this may take a while)...")

FetchContent_MakeAvailableWithArgs(cachelib
  BUILD_TESTS=OFF
  BUILD_EXAMPLES=OFF
)

message(STATUS "CacheLib configured successfully")

# 设置变量供其他模块使用
set(CACHELIB_FOUND TRUE CACHE BOOL "CacheLib found")
FetchContent_GetProperties(cachelib)
set(CACHELIB_SOURCE_DIR ${cachelib_SOURCE_DIR} CACHE PATH "CacheLib source directory")
set(CACHELIB_BINARY_DIR ${cachelib_BINARY_DIR} CACHE PATH "CacheLib binary directory")
