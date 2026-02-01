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

# 使用项目自定义函数声明 gflags 依赖
# 参数说明：
#   gflags - 依赖名称
#   gflags/gflags - GitHub 仓库路径
#   v2.2.2 - 版本标签（与 folly manifest 中指定的版本一致）
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
FetchContent_DeclareGitHubWithMirror(gflags
  gflags/gflags v2.2.2
  MD5=ff856ff64757f1381f7da260f79ba79b
)

# 使用项目的 FetchContent_MakeAvailableWithArgs 函数下载并编译 gflags
# 配置选项说明：
#   BUILD_SHARED_LIBS=OFF - 编译静态库
#   BUILD_STATIC_LIBS=ON - 启用静态库构建
#   BUILD_gflags_LIB=ON - 编译 gflags 库
FetchContent_MakeAvailableWithArgs(gflags
  BUILD_SHARED_LIBS=OFF
  BUILD_STATIC_LIBS=ON
  BUILD_gflags_LIB=ON
)
