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

# 使用项目自定义函数声明 fast_float 依赖
# 参数说明：
#   fast_float - 依赖名称
#   fastfloat/fast_float - GitHub 仓库路径
#   v8.0.0 - 版本标签（与 folly getdeps.py 使用的版本一致）
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
FetchContent_DeclareGitHubWithMirror(fast_float
  fastfloat/fast_float v8.0.0
  MD5=95fe166f7fda3bf18f87aef5c50e44bb
)

# 使用项目的 FetchContent_MakeAvailableWithArgs 函数下载并编译 fast_float
# fast_float 是 header-only 库，不需要编译，但需要添加到构建系统以便其他库使用
FetchContent_MakeAvailableWithArgs(fast_float)
