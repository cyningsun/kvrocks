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

# 使用项目自定义函数声明 folly 依赖
# 参数说明：
#   folly - 依赖名称
#   facebook/folly - GitHub 仓库路径
#   v2024.02.26.00 - 版本标签
#   MD5=... - 下载文件的 MD5 校验和，用于验证下载完整性
FetchContent_DeclareGitHubWithMirror(folly
  facebook/folly v2025.07.28.00
  MD5=67ab03f744c05e1be61ad8efe6834f16
)

# 获取已编译依赖的源码目录，用于传递给 folly
# folly 需要通过 find_package 找到这些依赖
FetchContent_GetProperties(boost)
FetchContent_GetProperties(double-conversion)
FetchContent_GetProperties(fast_float)
FetchContent_GetProperties(fmt)
FetchContent_GetProperties(gflags)
FetchContent_GetProperties(glog)
FetchContent_GetProperties(libevent)
FetchContent_GetProperties(gtest)

# ============================================================================
# 步骤 1: 编译和安装 gflags
# ============================================================================
# gflags 是 glog 的依赖，需要先编译
set(GFLAGS_INSTALL_DIR ${CMAKE_BINARY_DIR}/gflags-install)

if(NOT EXISTS ${GFLAGS_INSTALL_DIR}/lib/libgflags.a)
  message(STATUS "Building and installing gflags for folly...")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${gflags_SOURCE_DIR}
      -B ${gflags_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${GFLAGS_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_STATIC_LIBS=ON
      -DBUILD_gflags_LIB=ON
    RESULT_VARIABLE GFLAGS_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/gflags_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/gflags_config_error.log
  )
  
  if(NOT GFLAGS_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure gflags. Check ${CMAKE_BINARY_DIR}/gflags_config_error.log")
  endif()
  
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${gflags_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE GFLAGS_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/gflags_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/gflags_build_error.log
  )
  
  if(NOT GFLAGS_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build gflags. Check ${CMAKE_BINARY_DIR}/gflags_build_error.log")
  endif()
  
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${gflags_BINARY_DIR} --prefix ${GFLAGS_INSTALL_DIR}
    RESULT_VARIABLE GFLAGS_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/gflags_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/gflags_install_error.log
  )
  
  if(NOT GFLAGS_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install gflags. Check ${CMAKE_BINARY_DIR}/gflags_install_error.log")
  endif()
  
  message(STATUS "gflags built and installed successfully")
else()
  message(STATUS "gflags already installed at ${GFLAGS_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 2: 编译和安装 glog
# ============================================================================
# glog 依赖 gflags，需要设置 gflags 的路径
set(GLOG_INSTALL_DIR ${CMAKE_BINARY_DIR}/glog-install)

if(NOT EXISTS ${GLOG_INSTALL_DIR}/lib/libglog.a)
  message(STATUS "Building and installing glog for folly...")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${glog_SOURCE_DIR}
      -B ${glog_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${GLOG_INSTALL_DIR}
      -DCMAKE_PREFIX_PATH=${GFLAGS_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTING=OFF
      -DWITH_PKGCONFIG=OFF
    RESULT_VARIABLE GLOG_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/glog_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/glog_config_error.log
  )
  
  if(NOT GLOG_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure glog. Check ${CMAKE_BINARY_DIR}/glog_config_error.log")
  endif()
  
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${glog_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE GLOG_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/glog_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/glog_build_error.log
  )
  
  if(NOT GLOG_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build glog. Check ${CMAKE_BINARY_DIR}/glog_build_error.log")
  endif()
  
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${glog_BINARY_DIR} --prefix ${GLOG_INSTALL_DIR}
    RESULT_VARIABLE GLOG_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/glog_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/glog_install_error.log
  )
  
  if(NOT GLOG_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install glog. Check ${CMAKE_BINARY_DIR}/glog_install_error.log")
  endif()
  
  message(STATUS "glog built and installed successfully")
else()
  message(STATUS "glog already installed at ${GLOG_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 3: 编译和安装 double-conversion
# ============================================================================
# 在配置 folly 之前，需要先编译 double-conversion
# 因为 folly 的 find_package(DoubleConversion) 需要在配置阶段找到库文件
set(DOUBLE_CONVERSION_INSTALL_DIR ${CMAKE_BINARY_DIR}/double-conversion-install)

if(NOT EXISTS ${DOUBLE_CONVERSION_INSTALL_DIR}/lib/libdouble-conversion.a)
  message(STATUS "Building and installing double-conversion for folly...")
  
  # 配置 double-conversion
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${double-conversion_SOURCE_DIR}
      -B ${double-conversion_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${DOUBLE_CONVERSION_INSTALL_DIR}
      -DBUILD_TESTING=OFF
    RESULT_VARIABLE DC_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/double_conversion_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/double_conversion_config_error.log
  )
  
  if(NOT DC_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure double-conversion. Check ${CMAKE_BINARY_DIR}/double_conversion_config_error.log")
  endif()
  
  # 编译 double-conversion
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${double-conversion_BINARY_DIR}
      --config ${CMAKE_BUILD_TYPE}
      -j4
    RESULT_VARIABLE DC_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/double_conversion_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/double_conversion_build_error.log
  )
  
  if(NOT DC_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build double-conversion. Check ${CMAKE_BINARY_DIR}/double_conversion_build_error.log")
  endif()
  
  # 安装 double-conversion
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${double-conversion_BINARY_DIR}
      --prefix ${DOUBLE_CONVERSION_INSTALL_DIR}
    RESULT_VARIABLE DC_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/double_conversion_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/double_conversion_install_error.log
  )
  
  if(NOT DC_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install double-conversion. Check ${CMAKE_BINARY_DIR}/double_conversion_install_error.log")
  endif()
  
  message(STATUS "double-conversion built and installed successfully")
else()
  message(STATUS "double-conversion already installed at ${DOUBLE_CONVERSION_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 4: 编译和安装 Boost
# ============================================================================
# 在配置 folly 之前，需要先准备 Boost 的头文件和库文件
# 因为 folly 的 find_package(Boost) 需要找到正确结构的 Boost

# 设置 Boost 的安装目录（在构建目录中创建一个安装位置）
set(BOOST_INSTALL_DIR ${CMAKE_BINARY_DIR}/boost-install)

# 检查 Boost 是否已经安装头文件
if(NOT EXISTS ${BOOST_INSTALL_DIR}/include/boost/version.hpp)
  message(STATUS "Installing Boost headers and libraries for folly...")
  
  # 在配置阶段，我们需要先配置 Boost 的构建系统
  # 然后安装头文件到统一的位置
  
  # 步骤1: 重新配置 Boost 构建，确保包含所有需要的组件
  # 注意：不检查 CMakeCache.txt 是否存在，每次都重新配置以确保参数正确
  message(STATUS "Configuring Boost build system with all required components...")
  
  # 删除旧的 CMakeCache.txt 以确保配置更新
  file(REMOVE ${boost_BINARY_DIR}/CMakeCache.txt)
  
  execute_process(
    COMMAND ${CMAKE_COMMAND} 
      -S ${boost_SOURCE_DIR} 
      -B ${boost_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${BOOST_INSTALL_DIR}
      -DBUILD_TESTING=OFF
      -DBOOST_ENABLE_CMAKE=ON
    RESULT_VARIABLE BOOST_CONFIG_RESULT
    OUTPUT_VARIABLE BOOST_CONFIG_OUTPUT
    ERROR_VARIABLE BOOST_CONFIG_ERROR
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/boost_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/boost_config_error.log
  )
  
  if(NOT BOOST_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure Boost. Check ${CMAKE_BINARY_DIR}/boost_config_error.log for details")
  endif()
  
  message(STATUS "Boost configuration completed")
  
  # 步骤2: 编译 Boost 库（明确指定所有需要的组件目标）
  message(STATUS "Building Boost libraries (this may take several minutes)...")
  
  # Boost 的 CMake 系统中，每个库都有一个对应的目标
  # 目标名称格式：boost_<library_name>
  # 注意：Boost 1.83.0 中，regex 和 system 是 header-only 的，不需要编译
  set(BOOST_TARGETS
    boost_context
    boost_filesystem
    boost_program_options
    boost_thread
    boost_chrono
    boost_date_time
    boost_atomic
    boost_iostreams  # mvfst 需要
  )
  
  # 编译所有 Boost 组件
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${boost_BINARY_DIR} 
      --config ${CMAKE_BUILD_TYPE} 
      --target ${BOOST_TARGETS}
      -j4
    RESULT_VARIABLE BOOST_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/boost_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/boost_build_error.log
  )
  
  if(NOT BOOST_BUILD_RESULT EQUAL 0)
    message(WARNING "Boost build had issues. Check ${CMAKE_BINARY_DIR}/boost_build_error.log for details")
    # 继续尝试，可能部分组件已经编译成功
  else()
    message(STATUS "Boost libraries built successfully")
  endif()
  
  # 步骤3: 手动复制 Boost 头文件和库到统一位置
  # 不使用 cmake --install，因为它会尝试安装所有配置的库（包括未编译的）
  message(STATUS "Installing Boost headers and libraries to ${BOOST_INSTALL_DIR}...")
  
  # 创建安装目录结构
  file(MAKE_DIRECTORY ${BOOST_INSTALL_DIR}/include)
  file(MAKE_DIRECTORY ${BOOST_INSTALL_DIR}/lib)
  
  # 复制头文件：Boost 的头文件在各个 libs/*/include 目录下
  # 为了避免遗漏依赖，复制所有 Boost 库的头文件
  message(STATUS "Copying Boost headers...")
  
  # 使用 find 命令查找所有 include 目录并复制
  execute_process(
    COMMAND find ${boost_SOURCE_DIR}/libs -type d -name "include"
    OUTPUT_VARIABLE BOOST_INCLUDE_DIRS_OUTPUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # 将输出转换为列表
  string(REPLACE "\n" ";" BOOST_INCLUDE_DIRS_LIST "${BOOST_INCLUDE_DIRS_OUTPUT}")
  
  # 复制每个 include 目录
  foreach(lib_include_dir ${BOOST_INCLUDE_DIRS_LIST})
    if(EXISTS ${lib_include_dir})
      execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy_directory
          ${lib_include_dir}
          ${BOOST_INSTALL_DIR}/include
        ERROR_QUIET
      )
    endif()
  endforeach()
  
  # 复制 boost/version.hpp 等根级别的头文件
  if(EXISTS ${boost_SOURCE_DIR}/boost)
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${boost_SOURCE_DIR}/boost
        ${BOOST_INSTALL_DIR}/include/boost
      ERROR_QUIET
    )
  endif()
  
  # 复制已编译的库文件
  message(STATUS "Copying Boost libraries...")
  file(GLOB BOOST_LIBS "${boost_BINARY_DIR}/stage/lib/libboost_*.a")
  foreach(lib ${BOOST_LIBS})
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E copy ${lib} ${BOOST_INSTALL_DIR}/lib/
    )
  endforeach()
  
  message(STATUS "Boost installation completed")
else()
  message(STATUS "Boost already installed at ${BOOST_INSTALL_DIR}")
endif()

# 设置 Boost 相关变量，帮助 folly 的 find_package(Boost) 找到安装好的 Boost
# FindBoost.cmake 需要这些变量来定位 Boost
set(BOOST_ROOT ${BOOST_INSTALL_DIR} CACHE PATH "Boost root directory" FORCE)
set(Boost_INCLUDE_DIR ${BOOST_INSTALL_DIR}/include CACHE PATH "Boost include directory" FORCE)
set(BOOST_LIBRARYDIR ${BOOST_INSTALL_DIR}/lib CACHE PATH "Boost library directory" FORCE)
set(Boost_NO_SYSTEM_PATHS ON CACHE BOOL "Do not search system paths for Boost" FORCE)
set(Boost_USE_STATIC_LIBS ON CACHE BOOL "Use static Boost libraries" FORCE)

# 强制使用 FindBoost.cmake MODULE 模式而不是 Config 模式
# 因为 Boost 的 CMake Config 文件可能不完整
set(Boost_NO_BOOST_CMAKE ON CACHE BOOL "Do not use BoostConfig.cmake" FORCE)

# 设置 Boost 的详细输出，帮助调试
set(Boost_DEBUG OFF CACHE BOOL "Enable Boost debug output" FORCE)
set(Boost_DETAILED_FAILURE_MSG ON CACHE BOOL "Enable detailed Boost failure messages" FORCE)

# 在 Boost 1.83.0 中，regex 和 system 是 header-only 的，不需要编译
# 但是 FindBoost.cmake 默认会尝试查找它们的库文件
# 我们需要手动创建虚拟的库文件，让 FindBoost 认为它们存在
file(WRITE ${BOOST_INSTALL_DIR}/lib/libboost_regex.a "")
file(WRITE ${BOOST_INSTALL_DIR}/lib/libboost_system.a "")

# 设置 CMAKE_PREFIX_PATH，让 folly 的 find_package 能找到其他依赖
# 将所有依赖的安装目录和源码目录添加到搜索路径
set(FOLLY_CMAKE_PREFIX_PATH
  ${BOOST_INSTALL_DIR}
  ${DOUBLE_CONVERSION_INSTALL_DIR}
  ${GFLAGS_INSTALL_DIR}
  ${GLOG_INSTALL_DIR}
  ${boost_SOURCE_DIR}
  ${boost_BINARY_DIR}
  ${double-conversion_SOURCE_DIR}
  ${double-conversion_BINARY_DIR}
  ${fast_float_SOURCE_DIR}
  ${fmt_SOURCE_DIR}
  ${fmt_BINARY_DIR}
  ${gflags_SOURCE_DIR}
  ${gflags_BINARY_DIR}
  ${glog_SOURCE_DIR}
  ${glog_BINARY_DIR}
  ${libevent_SOURCE_DIR}
  ${libevent_BINARY_DIR}
  ${gtest_SOURCE_DIR}
  ${gtest_BINARY_DIR}
)

# 将依赖路径添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${FOLLY_CMAKE_PREFIX_PATH})

# ============================================================================
# 步骤 3.5: 编译和安装 fmt（为 folly 使用）
# ============================================================================
# 主项目已经使用 fmt 9.1.0（在 cmake/fmt.cmake 中配置）
# 为了让 folly 找到 fmt，需要先编译和安装它
set(FMT_INSTALL_DIR ${CMAKE_BINARY_DIR}/fmt-install CACHE PATH "fmt install directory")

if(NOT EXISTS ${FMT_INSTALL_DIR}/lib/libfmt.a)
  message(STATUS "Building and installing fmt for folly...")
  
  # 获取 fmt 源码（复用主项目的声明）
  FetchContent_GetProperties(fmt)
  if(NOT fmt_POPULATED)
    FetchContent_Populate(fmt)
  endif()
  
  # 设置 fmt 的二进制目录
  set(fmt_INSTALL_BINARY_DIR ${CMAKE_BINARY_DIR}/fmt-install-build)
  
  # 配置 fmt
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${fmt_SOURCE_DIR}
      -B ${fmt_INSTALL_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${FMT_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DFMT_TEST=OFF
      -DFMT_DOC=OFF
    RESULT_VARIABLE FMT_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fmt_install_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fmt_install_config_error.log
  )
  
  if(NOT FMT_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure fmt. Check ${CMAKE_BINARY_DIR}/fmt_install_config_error.log")
  endif()
  
  # 编译 fmt
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${fmt_INSTALL_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE FMT_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fmt_install_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fmt_install_build_error.log
  )
  
  if(NOT FMT_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build fmt. Check ${CMAKE_BINARY_DIR}/fmt_install_build_error.log")
  endif()
  
  # 安装 fmt
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${fmt_INSTALL_BINARY_DIR} --prefix ${FMT_INSTALL_DIR}
    RESULT_VARIABLE FMT_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fmt_install_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fmt_install_install_error.log
  )
  
  if(NOT FMT_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install fmt. Check ${CMAKE_BINARY_DIR}/fmt_install_install_error.log")
  endif()
  
  message(STATUS "fmt built and installed successfully for folly")
else()
  message(STATUS "fmt already installed at ${FMT_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 3.6: 编译和安装 libevent（为 folly 使用）
# ============================================================================
# folly 需要 libevent，为了避免构建树路径依赖问题，单独编译和安装 libevent
set(LIBEVENT_INSTALL_DIR ${CMAKE_BINARY_DIR}/libevent-install CACHE PATH "Libevent install directory")

if(NOT EXISTS ${LIBEVENT_INSTALL_DIR}/lib/libevent.a)
  message(STATUS "Building and installing libevent for folly...")
  
  # 获取 libevent 源码
  FetchContent_GetProperties(libevent)
  if(NOT libevent_POPULATED)
    FetchContent_Populate(libevent)
  endif()
  
  # 设置 libevent 的二进制目录
  set(libevent_INSTALL_BINARY_DIR ${CMAKE_BINARY_DIR}/libevent-install-build)
  
  # 判断是否需要 OpenSSL
  set(libevent_disable_ssl ON)
  if(ENABLE_OPENSSL)
    set(libevent_disable_ssl OFF)
  endif()
  
  # 配置 libevent
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${libevent_SOURCE_DIR}
      -B ${libevent_INSTALL_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${LIBEVENT_INSTALL_DIR}
      -DEVENT__DISABLE_TESTS=ON
      -DEVENT__DISABLE_REGRESS=ON
      -DEVENT__DISABLE_SAMPLES=ON
      -DEVENT__DISABLE_OPENSSL=${libevent_disable_ssl}
      -DEVENT__DISABLE_MBEDTLS=ON
      -DEVENT__LIBRARY_TYPE=STATIC
      -DEVENT__DISABLE_BENCHMARK=ON
      -DEVENT__DISABLE_DEBUG_MODE=ON
      -DBUILD_SHARED_LIBS=OFF
    RESULT_VARIABLE LIBEVENT_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/libevent_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/libevent_config_error.log
  )
  
  if(NOT LIBEVENT_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure libevent. Check ${CMAKE_BINARY_DIR}/libevent_config_error.log")
  endif()
  
  # 编译 libevent
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${libevent_INSTALL_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE LIBEVENT_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/libevent_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/libevent_build_error.log
  )
  
  if(NOT LIBEVENT_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build libevent. Check ${CMAKE_BINARY_DIR}/libevent_build_error.log")
  endif()
  
  # 安装 libevent
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${libevent_INSTALL_BINARY_DIR} --prefix ${LIBEVENT_INSTALL_DIR}
    RESULT_VARIABLE LIBEVENT_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/libevent_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/libevent_install_error.log
  )
  
  if(NOT LIBEVENT_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install libevent. Check ${CMAKE_BINARY_DIR}/libevent_install_error.log")
  endif()
  
  message(STATUS "libevent built and installed successfully for folly")
else()
  message(STATUS "libevent already installed at ${LIBEVENT_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 3.7: 编译和安装 zstd（为 Facebook 库使用）
# ============================================================================
# fizz, wangle, mvfst, fbthrift, cachelib 都需要 zstd
# 为了避免构建树路径依赖问题，单独编译和安装 zstd

set(ZSTD_INSTALL_DIR ${CMAKE_BINARY_DIR}/zstd-install CACHE PATH "Zstd install directory")

if(NOT EXISTS ${ZSTD_INSTALL_DIR}/lib/libzstd.a)
  message(STATUS "Building and installing zstd for Facebook libraries...")
  
  # 获取 zstd 源码（复用 zstd.cmake 的声明）
  FetchContent_GetProperties(zstd)
  if(NOT zstd_POPULATED)
    FetchContent_Populate(zstd)
  endif()
  
  # 设置 zstd 的二进制目录
  set(zstd_INSTALL_BINARY_DIR ${CMAKE_BINARY_DIR}/zstd-install-build)
  
  # 配置 zstd（使用 build/cmake）
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${zstd_SOURCE_DIR}/build/cmake
      -B ${zstd_INSTALL_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${ZSTD_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DZSTD_BUILD_PROGRAMS=OFF
      -DZSTD_BUILD_CONTRIB=OFF
      -DZSTD_BUILD_TESTS=OFF
    RESULT_VARIABLE ZSTD_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/zstd_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/zstd_config_error.log
  )
  
  if(NOT ZSTD_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure zstd. Check ${CMAKE_BINARY_DIR}/zstd_config_error.log")
  endif()
  
  # 编译 zstd
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${zstd_INSTALL_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE ZSTD_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/zstd_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/zstd_build_error.log
  )
  
  if(NOT ZSTD_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build zstd. Check ${CMAKE_BINARY_DIR}/zstd_build_error.log")
  endif()
  
  # 安装 zstd
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${zstd_INSTALL_BINARY_DIR} --prefix ${ZSTD_INSTALL_DIR}
    RESULT_VARIABLE ZSTD_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/zstd_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/zstd_install_error.log
  )
  
  if(NOT ZSTD_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install zstd. Check ${CMAKE_BINARY_DIR}/zstd_install_error.log")
  endif()
  
  message(STATUS "zstd built and installed successfully for Facebook libraries")
else()
  message(STATUS "zstd already installed at ${ZSTD_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 4: 编译和安装 folly
# ============================================================================
# 设置 folly 的安装目录
set(FOLLY_INSTALL_DIR ${CMAKE_BINARY_DIR}/folly-install)

if(NOT EXISTS ${FOLLY_INSTALL_DIR}/lib/libfolly.a)
  message(STATUS "Building and installing folly (this may take a while)...")
  
  # 设置 CMAKE_MODULE_PATH，让 folly 能找到自定义的 Find 模块
  set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${PROJECT_SOURCE_DIR}/cmake/modules" CACHE STRING "CMake module path")
  
  # 获取 folly 源码路径
  FetchContent_GetProperties(folly)
  if(NOT folly_POPULATED)
    FetchContent_Populate(folly)
  endif()
  
  # 配置 folly
  # 构建 CMAKE_PREFIX_PATH 字符串（用分号分隔）
  # 包含 LIBEVENT_INSTALL_DIR，让 folly 能找到已安装的 libevent
  set(FOLLY_PREFIX_PATH "${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR};${FMT_INSTALL_DIR};${LIBEVENT_INSTALL_DIR}")
  
  # 设置 Boost 的路径（让 folly 能找到 Boost）
  set(BOOST_ROOT ${BOOST_INSTALL_DIR})
  set(BOOST_INCLUDEDIR ${BOOST_INSTALL_DIR}/include)
  set(BOOST_LIBRARYDIR ${BOOST_INSTALL_DIR}/lib)
  
  # 设置 libevent 的路径（使用已安装的 libevent）
  set(LIBEVENT_INCLUDE_DIR "${LIBEVENT_INSTALL_DIR}/include")
  set(LIBEVENT_LIB_DIR "${LIBEVENT_INSTALL_DIR}/lib")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${folly_SOURCE_DIR}
      -B ${folly_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${FOLLY_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${FOLLY_PREFIX_PATH}"
      -DCMAKE_MODULE_PATH=${PROJECT_SOURCE_DIR}/cmake/modules
      # 使用统一的编译标志
      "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
      "-DBOOST_ROOT=${BOOST_ROOT}"
      "-DBOOST_INCLUDEDIR=${BOOST_INCLUDEDIR}"
      "-DBOOST_LIBRARYDIR=${BOOST_LIBRARYDIR}"
      "-DBoost_NO_SYSTEM_PATHS=ON"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DLIBEVENT_CORE_LIB=${LIBEVENT_LIB_DIR}/libevent_core.a"
      "-DLIBEVENT_PTHREADS_LIB=${LIBEVENT_LIB_DIR}/libevent_pthreads.a"
      "-DFASTFLOAT_INCLUDE_DIR=${fast_float_SOURCE_DIR}/include"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
      -DBUILD_BENCHMARKS=OFF
      -DPYTHON_EXTENSIONS=OFF
    RESULT_VARIABLE FOLLY_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/folly_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/folly_config_error.log
  )
  
  if(NOT FOLLY_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure folly. Check ${CMAKE_BINARY_DIR}/folly_config_error.log")
  endif()
  
  # 编译 folly
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${folly_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE FOLLY_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/folly_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/folly_build_error.log
  )
  
  if(NOT FOLLY_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build folly. Check ${CMAKE_BINARY_DIR}/folly_build_error.log")
  endif()
  
  # 安装 folly
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${folly_BINARY_DIR} --prefix ${FOLLY_INSTALL_DIR}
    RESULT_VARIABLE FOLLY_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/folly_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/folly_install_error.log
  )
  
  if(NOT FOLLY_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install folly. Check ${CMAKE_BINARY_DIR}/folly_install_error.log")
  endif()
  
  message(STATUS "folly built and installed successfully")
else()
  message(STATUS "folly already installed at ${FOLLY_INSTALL_DIR}")
endif()

# 将 folly 的安装目录添加到 CMAKE_PREFIX_PATH，让其他库能找到它
list(APPEND CMAKE_PREFIX_PATH ${FOLLY_INSTALL_DIR})

# 注意：不需要在这里调用 find_package(folly)，因为：
# 1. folly 已经安装到 FOLLY_INSTALL_DIR
# 2. 其他 Facebook 库会通过 CMAKE_PREFIX_PATH 自动找到它
# 3. folly-config.cmake 在构建树中有路径问题，但在安装后是正确的

