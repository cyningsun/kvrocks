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

FetchContent_DeclareGitHubWithMirror(uring
  axboe/liburing liburing-2.6
  MD5=6add9ae4432363aec3f001d98868abf6
)

FetchContent_GetProperties(uring)
if(NOT uring_POPULATED)
  FetchContent_Populate(uring)

  execute_process(COMMAND ${uring_SOURCE_DIR}/configure 
    WORKING_DIRECTORY ${uring_BINARY_DIR}
  ) 

  
  add_custom_target(make_uring
    COMMAND ${MAKE_COMMAND} ${uring_SOURCE_DIR}/
    WORKING_DIRECTORY ${uring_BINARY_DIR}
    BYPRODUCTS ${uring_SOURCE_DIR}/lib/liburing.a
  )
endif()

add_library(uring INTERFACE)
target_include_directories(uring INTERFACE $<BUILD_INTERFACE:${uring_BINARY_DIR}/include>)
target_link_libraries(uring INTERFACE $<BUILD_INTERFACE:${uring_BINARY_DIR}/lib/liburing.a>)
add_dependencies(uring make_uring)