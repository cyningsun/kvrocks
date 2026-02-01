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

# 使用项目自定义函数声明 double-conversion 依赖
# 参数说明：
#   double-conversion - 依赖名称
#   google/double-conversion - GitHub 仓库路径
#   v3.3.0 - 版本标签（与 folly getdeps.py 使用的版本一致）
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
FetchContent_DeclareGitHubWithMirror(double-conversion
  google/double-conversion v3.3.0
  MD5=08531ee4347d8ed35a016478d16f3d98
)

# 使用项目的 FetchContent_MakeAvailableWithArgs 函数下载并编译 double-conversion
# 配置选项说明：
#   BUILD_TESTING=OFF - 禁用测试构建，加快编译速度
FetchContent_MakeAvailableWithArgs(double-conversion
  BUILD_TESTING=OFF
)
