include_guard()

include(cmake/utils.cmake)

FetchContent_DeclareGitHubWithMirror(folly
    facebook/folly v2024.04.15.00
    MD5=beacd86d63cd71c904632262e6c36f60874d78ba
)


exec_program(python3 ${PROJECT_SOURCE_DIR}/third-party/folly ARGS
build/fbcode_builder/getdeps.py show-inst-dir OUTPUT_VARIABLE
FOLLY_INST_PATH)
exec_program(ls ARGS -d ${FOLLY_INST_PATH}/../boost* OUTPUT_VARIABLE
BOOST_INST_PATH)
exec_program(ls ARGS -d ${FOLLY_INST_PATH}/../fmt* OUTPUT_VARIABLE
FMT_INST_PATH)
exec_program(ls ARGS -d ${FOLLY_INST_PATH}/../gflags* OUTPUT_VARIABLE
GFLAGS_INST_PATH)
set(Boost_DIR ${BOOST_INST_PATH}/lib/cmake/Boost-1.78.0)
if(EXISTS ${FMT_INST_PATH}/lib64)
  set(fmt_DIR ${FMT_INST_PATH}/lib64/cmake/fmt)
else()
  set(fmt_DIR ${FMT_INST_PATH}/lib/cmake/fmt)
endif()
set(gflags_DIR ${GFLAGS_INST_PATH}/lib/cmake/gflags)

exec_program(sed ARGS -i 's/gflags_shared//g'
${FOLLY_INST_PATH}/lib/cmake/folly/folly-targets.cmake)

include(${FOLLY_INST_PATH}/lib/cmake/folly/folly-config.cmake)
