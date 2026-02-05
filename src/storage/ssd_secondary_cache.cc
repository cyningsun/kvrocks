// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include "ssd_secondary_cache.h"

#include <filesystem>
#include <memory>

#include "cachelib_wrapper.h"
#include "common/logging.h"
#include "config/config.h"

namespace engine {

std::shared_ptr<rocksdb::SecondaryCache> NewSsdSecondaryCache(const Config* config) {
  if (!config) {
    ERROR("Config is null");
    return nullptr;
  }

  const auto& rocks_db = config->rocks_db;

  // Check if SSD secondary cache is enabled
  if (!rocks_db.enable_ssd_secondary_cache) {
    INFO("SSD secondary cache is disabled");
    return nullptr;
  }

  // Validate configuration
  if (rocks_db.ssd_cache_size <= 0) {
    ERROR("SSD cache size must be greater than 0, got: {}", rocks_db.ssd_cache_size);
    return nullptr;
  }

  if (rocks_db.ssd_cache_file_path.empty()) {
    ERROR("SSD cache file path must be specified");
    return nullptr;
  }

  // Create cache directory if it doesn't exist
  std::filesystem::path cache_path(rocks_db.ssd_cache_file_path);
  std::filesystem::path cache_dir = cache_path.parent_path();

  if (!cache_dir.empty()) {
    std::error_code ec;
    std::filesystem::create_directories(cache_dir, ec);
    if (ec) {
      ERROR("Failed to create cache directory: {}, error: {}", cache_dir.string(), ec.message());
      return nullptr;
    }
  }

  // Configure CacheLib options using the local wrapper
  RocksCachelibOptions cachelib_opts;
  cachelib_opts.cacheName = "datanode_ssd_cache";
  cachelib_opts.fileName = rocks_db.ssd_cache_file_path;
  cachelib_opts.size = static_cast<size_t>(rocks_db.ssd_cache_size) * 1024 * 1024;  // MB to bytes
  cachelib_opts.blockSize = rocks_db.ssd_cache_block_size;
  cachelib_opts.regionSize =
      static_cast<size_t>(rocks_db.ssd_cache_region_size) * 1024 * 1024;  // MB to bytes
  cachelib_opts.admPolicy =
      rocks_db.ssd_cache_admission_policy.empty() ? "random" : rocks_db.ssd_cache_admission_policy;
  cachelib_opts.admProbability =
      static_cast<double>(rocks_db.ssd_cache_admission_probability) / 100.0;  // config: 0-100 -> 0.0-1.0
  cachelib_opts.maxWriteRate =
      static_cast<uint64_t>(rocks_db.ssd_cache_max_write_rate) * 1024 * 1024;  // MB/s to bytes/s
  cachelib_opts.admissionWriteRate = cachelib_opts.maxWriteRate;               // Use same value
  cachelib_opts.volatileSize =
      static_cast<size_t>(rocks_db.ssd_cache_volatile_size) * 1024 * 1024;  // MB to bytes
  cachelib_opts.bktPower = 12;                                              // 4096 buckets
  cachelib_opts.lockPower = 12;                                             // 4096 locks
  cachelib_opts.fb303Stats = false;  // Not supported in open source version
  cachelib_opts.oncallName = "";     // Not supported in open source version

  try {
    // Use local RocksCachelibWrapper (adapted from CacheLib)
    auto cache = NewRocksCachelibWrapper(cachelib_opts);

    if (cache) {
      INFO("SSD secondary cache created successfully: file={}, capacity={}MB, volatile_size={}MB, "
           "admission_policy={}, max_write_rate={}MB/s",
           rocks_db.ssd_cache_file_path, rocks_db.ssd_cache_size, rocks_db.ssd_cache_volatile_size,
           rocks_db.ssd_cache_admission_policy, rocks_db.ssd_cache_max_write_rate);
    } else {
      ERROR("Failed to create SSD secondary cache");
    }

    return cache;
  } catch (const std::exception& e) {
    ERROR("Exception while creating SSD secondary cache: {}", e.what());
    return nullptr;
  }
}

}  // namespace engine

