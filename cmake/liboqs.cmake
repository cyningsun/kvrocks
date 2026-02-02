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

# liboqs - 后量子加密算法库
# 依赖：OpenSSL 
# 使用 nist-branch-snapshot-2018-11 标签
FetchContent_DeclareGitHubWithMirror(liboqs
  open-quantum-safe/liboqs 0.12.0
  MD5=c45b03804626c6d7332163f93af4711f
)

# 获取 liboqs 源码
FetchContent_GetProperties(liboqs)
if(NOT liboqs_POPULATED)
  FetchContent_Populate(liboqs)
  message(STATUS "liboqs source downloaded to: ${liboqs_SOURCE_DIR}")
endif()

# 设置 liboqs 的安装目录
set(LIBOQS_INSTALL_DIR ${CMAKE_BINARY_DIR}/liboqs-install)

# 检查是否已经安装
if(NOT EXISTS ${LIBOQS_INSTALL_DIR}/lib/liboqs.a)
  message(STATUS "Building and installing liboqs...")
  
  # 确保 OpenSSL 已找到
  find_package(OpenSSL REQUIRED)
  
  # 配置 liboqs
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${liboqs_SOURCE_DIR}
      -B ${liboqs_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${LIBOQS_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DOQS_BUILD_ONLY_LIB=ON
      -DOQS_USE_OPENSSL=ON
      -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}
    RESULT_VARIABLE LIBOQS_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liboqs_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liboqs_config_error.log
  )
  
  if(NOT LIBOQS_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure liboqs. Check ${CMAKE_BINARY_DIR}/liboqs_config_error.log")
  endif()
  
  # 编译 liboqs
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${liboqs_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE LIBOQS_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liboqs_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liboqs_build_error.log
  )
  
  if(NOT LIBOQS_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build liboqs. Check ${CMAKE_BINARY_DIR}/liboqs_build_error.log")
  endif()
  
  # 安装 liboqs
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${liboqs_BINARY_DIR} --prefix ${LIBOQS_INSTALL_DIR}
    RESULT_VARIABLE LIBOQS_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liboqs_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liboqs_install_error.log
  )
  
  if(NOT LIBOQS_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install liboqs. Check ${CMAKE_BINARY_DIR}/liboqs_install_error.log")
  endif()
  
  message(STATUS "liboqs built and installed successfully")
else()
  message(STATUS "liboqs already installed at ${LIBOQS_INSTALL_DIR}")
endif()

# 创建 liboqs 导入目标
if(NOT TARGET oqs::oqs)
  add_library(oqs::oqs STATIC IMPORTED)
  set_target_properties(oqs::oqs PROPERTIES
    IMPORTED_LOCATION ${LIBOQS_INSTALL_DIR}/lib/liboqs.a
    INTERFACE_INCLUDE_DIRECTORIES ${LIBOQS_INSTALL_DIR}/include
  )
endif()

# 设置变量供其他模块使用
set(LIBOQS_FOUND TRUE CACHE BOOL "liboqs found")
set(LIBOQS_INCLUDE_DIR ${LIBOQS_INSTALL_DIR}/include CACHE PATH "liboqs include directory")
set(LIBOQS_LIBRARY ${LIBOQS_INSTALL_DIR}/lib/liboqs.a CACHE FILEPATH "liboqs library")
