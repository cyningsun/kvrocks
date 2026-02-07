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

# Bridge FindGTest: maps googletest add_subdirectory targets to expected variables.
# Used by snappy (to disable tests) and CacheLib (to find gtest).

if(TARGET gtest)
  set(GTEST_FOUND TRUE)
  set(GTest_FOUND TRUE)
  set(GTEST_LIBRARIES gtest)
  set(GTEST_BOTH_LIBRARIES "gtest;gtest_main")
  set(GTEST_MAIN_LIBRARY gtest_main)

  # Include directories are propagated automatically via the gtest target
  # (googletest has PUBLIC target_include_directories). No need to set GTEST_INCLUDE_DIR.

  # Create GTest::gtest and GTest::gtest_main aliases if not present
  if(NOT TARGET GTest::gtest)
    add_library(GTest::gtest ALIAS gtest)
  endif()
  if(NOT TARGET GTest::gtest_main)
    add_library(GTest::gtest_main ALIAS gtest_main)
  endif()
else()
  set(GTEST_FOUND FALSE)
  set(GTest_FOUND FALSE)
endif()
