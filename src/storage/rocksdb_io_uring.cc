/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

 #include "rocksdb_io_uring.h"

 #include <atomic>
 
 namespace engine {
 
 // Global flag read by RocksDB via RocksDbIOUringEnable().
 std::atomic<int> g_rocksdb_io_uring_enable{0};
 
 void SetRocksDbIOUringEnable(bool enable) {
   g_rocksdb_io_uring_enable.store(enable ? 1 : 0, std::memory_order_release);
 }
 
 }  // namespace engine
 
 // C symbol for RocksDB to query whether io_uring is enabled.
 // Returns 1 if enabled, 0 if disabled.
 extern "C" int RocksDbIOUringEnable(void) {
   return engine::g_rocksdb_io_uring_enable.load(std::memory_order_acquire);
 }