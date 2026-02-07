# Bridge GTestConfig.cmake: maps gtest add_subdirectory targets to GTest CONFIG expectations.
# CacheLib uses find_package(GTest CONFIG REQUIRED).

if(NOT TARGET GTest::gtest)
  if(TARGET gtest)
    add_library(GTest::gtest ALIAS gtest)
  endif()
endif()

if(NOT TARGET GTest::gtest_main)
  if(TARGET gtest_main)
    add_library(GTest::gtest_main ALIAS gtest_main)
  endif()
endif()

if(NOT TARGET GTest::gmock)
  if(TARGET gmock)
    add_library(GTest::gmock ALIAS gmock)
  endif()
endif()

if(NOT TARGET GTest::gmock_main)
  if(TARGET gmock_main)
    add_library(GTest::gmock_main ALIAS gmock_main)
  endif()
endif()

set(GTest_FOUND TRUE)
set(GTEST_FOUND TRUE)
