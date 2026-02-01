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

# 引入项目的工具函数库，包含 FetchContent_DeclareGitHubWithMirror 等自定义函数
include(cmake/utils.cmake)

# 使用项目自定义函数声明 boost 依赖
# 参数说明：
#   boost - 依赖名称
#   URL - Boost 1.83.0 GitHub release 下载地址（与 folly manifest 中指定的版本一致）
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
# 注意：使用 Boost 1.83.0 而不是 1.84.0，因为：
#   - folly 官方使用和测试的是 1.83.0
#   - 1.84.0 中 regex 和 system 变成了 header-only，导致 FindBoost.cmake 找不到库文件
# 注意：使用 GitHub release 而不是 JFrog，因为 JFrog 的 Boost 仓库已停用
FetchContent_Declare(boost
  URL https://github.com/boostorg/boost/releases/download/boost-1.83.0/boost-1.83.0.tar.gz
  URL_HASH MD5=58db882403e0c16b334760f3c3b76ff8
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# 在调用 FetchContent_MakeAvailableWithArgs 之前设置 Boost 构建选项
# 这些变量会在 Boost 的 CMakeLists.txt 中被读取

# 包含 folly 需要的 Boost 组件及其依赖，减少编译时间
# 主要组件：
#   context - 上下文切换库（需要编译）
#   filesystem - 文件系统操作库（需要编译）
#   program_options - 命令行参数解析库（需要编译）
#   regex - 正则表达式库（需要编译）
#   system - 系统错误库（需要编译）
#   thread - 线程支持库（需要编译）
# 依赖组件：
#   chrono - 时间库（thread 的依赖）
#   date_time - 日期时间库（thread 的依赖）
#   atomic - 原子操作库（thread 的依赖）
set(BOOST_INCLUDE_LIBRARIES context filesystem program_options regex system thread chrono date_time atomic CACHE STRING "Boost libraries to build")

# 禁用 Boost 的测试构建，加快编译速度
set(BUILD_TESTING OFF CACHE BOOL "Build Boost tests")

# 启用 Boost 的 CMake 构建系统
set(BOOST_ENABLE_CMAKE ON CACHE BOOL "Enable CMake build for Boost")

# 使用项目的 FetchContent_MakeAvailableWithArgs 函数下载并编译 boost
# 注意：由于 BOOST_INCLUDE_LIBRARIES 是列表类型，不能通过参数传递
# 所以在调用前使用 set() 设置变量
FetchContent_MakeAvailableWithArgs(boost)
