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

# 使用项目自定义函数声明 glog 依赖
# 参数说明：
#   glog - 依赖名称
#   google/glog - GitHub 仓库路径
#   v0.5.0 - 版本标签（与 folly manifest 中指定的版本一致）
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
FetchContent_DeclareGitHubWithMirror(glog
  google/glog v0.5.0
  MD5=2286d65cc3714b26e085a3bc62ce38a5
)

# 获取 gflags 的构建目录，让 glog 能找到我们构建的 gflags
# 而不是系统安装的 gflags
FetchContent_GetProperties(gflags)

# 将 gflags 构建目录添加到 CMAKE_PREFIX_PATH
# 这样 glog 的 find_package(gflags) 会优先找到我们构建的版本
list(APPEND CMAKE_PREFIX_PATH ${gflags_BINARY_DIR})

# 使用项目的 FetchContent_MakeAvailableWithArgs 函数下载并编译 glog
# 配置选项说明：
#   BUILD_SHARED_LIBS=OFF - 编译静态库
#   BUILD_TESTING=OFF - 禁用测试构建
#   WITH_PKGCONFIG=OFF - 禁用 pkg-config 支持
#   WITH_GFLAGS=OFF - 禁用 gflags 依赖，因为我们已经有了
FetchContent_MakeAvailableWithArgs(glog
  BUILD_SHARED_LIBS=OFF
  BUILD_TESTING=OFF
  WITH_PKGCONFIG=OFF
  WITH_GFLAGS=OFF
)

