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

include_guard()

include(cmake/utils.cmake)

# 使用 spdlog 1.11.0 以兼容 fmt 9.1.0（folly 依赖）
FetchContent_DeclareGitHubWithMirror(spdlog
  gabime/spdlog v1.11.0
  MD5=cd620e0f103737a122a3b6539bd0a57a
)

FetchContent_MakeAvailableWithArgs(spdlog
  SPDLOG_FMT_EXTERNAL=ON
)
