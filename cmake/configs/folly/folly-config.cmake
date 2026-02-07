# Bridge: folly is available via add_subdirectory
# This file satisfies find_package(folly CONFIG REQUIRED) for downstream FB libs

if(NOT TARGET folly)
  message(FATAL_ERROR "Bridge error: folly target not available (expected from add_subdirectory)")
endif()

# Create Folly::folly alias if not already present
if(NOT TARGET Folly::folly)
  add_library(Folly::folly ALIAS folly)
endif()

set(folly_FOUND TRUE)
set(FOLLY_FOUND TRUE)
set(FOLLY_LIBRARIES Folly::folly)

# Include directories are propagated automatically via the Folly::folly target
# (folly has PUBLIC target_include_directories). No need to set FOLLY_INCLUDE_DIR.
