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

# liboqs - Post-quantum cryptography library
# Note: Currently not directly used by kvrocks source code,
#       but kept available for potential future use by fizz.
FetchContent_DeclareGitHubWithMirror(liboqs
  open-quantum-safe/liboqs 0.12.0
  MD5=c45b03804626c6d7332163f93af4711f
)

FetchContent_GetProperties(liboqs)
if(NOT liboqs_POPULATED)
  FetchContent_Populate(liboqs)
  # Build liboqs via add_subdirectory with minimal configuration.
  # EXCLUDE_FROM_ALL: only build if something depends on it.
  set(OQS_BUILD_ONLY_LIB ON CACHE BOOL "" FORCE)
  set(OQS_DIST_BUILD OFF CACHE BOOL "" FORCE)
  add_subdirectory(${liboqs_SOURCE_DIR} ${liboqs_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# The 'oqs' target is now available from add_subdirectory.
# Use oqs::oqs alias if needed (liboqs does not create one by default).
if(TARGET oqs AND NOT TARGET oqs::oqs)
  add_library(oqs::oqs ALIAS oqs)
endif()
