#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sp_store'

def measure_time 
  start = Time.now
  yield
  puts ( Time.now - start )
end

# storage & cache information  
block_size              = 2**20
block_count             = 2048
node_cache_size         = 2**9
session_cache_size      = 64
load_store              = true
delete_store            = false

# choose between mock or real p_chip 
mock_p_chip             = true

# benchmark options
write_data_gen          = false
run_benchmark           = false

test_command, test_type = ARGV[0], ARGV[1]

if test_command
  raise ArgumentError, "using --test <test_name> to run benchmark" unless test_command=="--test"
  raise ArgumentError, "test \"#{test_type}\" does not exist" unless SpStore::Benchmark::SyntheticBenchmark.method_defined? test_type
  run_benchmark = true
end

################ initialization ############################

# initialize sp_store controller
sp_store_controller   = nil
measure_time do
  sp_store_controller = SpStore::Benchmark::StoreSetup.sp_store_controller( block_size, block_count, 
                        node_cache_size, session_cache_size, load_store, mock_p_chip )
  puts "Initialization time for sp store (secs):"
end

# initialize bare controller
bare_controller       = nil
measure_time do
  bare_controller     = SpStore::Benchmark::StoreSetup.bare_controller( block_size, block_count, load_store )
  puts "Initialization time for mock store (secs):"
end

############### Benchmark Test Setup ########################

benchmark = SpStore::Benchmark::SyntheticBenchmark.new block_size, block_count, 
                     SpStore::Benchmark::StoreSetup.disk_directory, sp_store_controller, bare_controller

# pre-generate write data
measure_time do
  benchmark.generate_write_data_file
  puts "Write data pre-generation (secs):"
end if write_data_gen

################### Running Benchmark #######################

eval "benchmark.#{ARGV[1]}" if run_benchmark

################### Delete Existing Store ###################

SpStore::Storage::DiskStore.delete_store if delete_store
SpStore::Mocks::FileStore.delete_store   if delete_store
