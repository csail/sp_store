#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sp_store'
require 'optparse'

############## storage & cache information #################  

block_size              = 2**20
block_count             = 2048
node_cache_size         = 2**9
session_cache_size      = 64

################ parse command options #####################

 options = {}
 
 optparse = OptionParser.new do|opts|
   # Set a banner, displayed at the top of the help screen.
   opts.banner = "Usage: sp_store [options]"
 
   # Define the options, and what they do
   options[:init] = false
   opts.on( '-i', '--init', 'Create a new disk storage' ) do
     options[:init] = true
   end
   options[:delete] = false   
   opts.on( '-d', '--delete', 'Delete the disk storage' ) do
     options[:delete] = true
   end
   options[:mock_p] = false   
   opts.on( '--mock-p', 'Use mock P chip for testing' ) do
     options[:mock_p] = true
   end
   options[:soft_hash_engine] = false   
   opts.on( '--soft-hash-engine', 'Use software implemented hash engine' ) do
     options[:soft_hash_engine] = true
   end   
   options[:write_data] = false   
   opts.on( '--write-data', 'Pre-generate random bytes for block write' ) do
     options[:write_data] = true
   end
   options[:detailed_time] = nil
   opts.on( '--detailed-time FILE', 'Detailed timing analysis written in FILE' ) do |detail_file|
     options[:detailed_time] = detail_file
   end
   options[:node_hit_rate] = false   
   opts.on( '--nodeCache-hitRate', 'Measure tree cache hit rate' ) do
     options[:node_hit_rate] = true
   end
   options[:node_hit_rate_detail] = false   
   opts.on( '--nodeCache-hitRate-detail', 'Measure tree cache hit rate (output detailed info)' ) do
     options[:node_hit_rate_detail] = true
   end
   options[:test] = nil
   opts.on( '-t', '--test TEST-NAME', 'Run benchmark TEST-NAME' ) do |test_type|
     options[:test] = test_type
   end
   options[:test_iter] = nil
   opts.on( '--test-iter TEST-TIMES', 'Run benchmark TEST-TIMES' ) do |test_iter|
     options[:test_iter] = test_iter
   end   
   options[:check_functionality] = false   
   opts.on( '--check-functionality', 'Check the system runs correctly on the disk' ) do 
     options[:check_functionality] = true
   end
   opts.on( '--block-size NUM', Integer, 'Block size (byte) (in log2)' ) do |size|
     options[:block_size] = size
   end   
   opts.on( '--block-count NUM', Integer, 'Block count (in log2)' ) do |count|
     options[:block_count] = count
   end
   opts.on( '--cache-size NUM', Integer, 'Node cache size (in log2)') do |c_size|
     options[:cache_size] = c_size
   end 
   # This displays the help screen
   opts.on( '-h', '--help', 'Display this screen' ) do
     puts opts
     exit
   end
 end.parse!

##################  options setting  ########################

block_size              = 2**options[:block_size]  if options[:block_size]  && options[:block_size]!= 0
block_count             = 2**options[:block_count] if options[:block_count] && options[:block_count]!= 0
node_cache_size         = 2**options[:cache_size]  if options[:cache_size]  && options[:cache_size]!= 0

load_store              = !options[:init]
# load store properties
if load_store
  block_size            = SpStore::Storage::DiskStore.load_store.block_size unless options[:block_size]
  block_count           = SpStore::Storage::DiskStore.load_store.blocks unless options[:block_count]
end

delete_store            = options[:delete]
soft_hash_engine        = options[:soft_hash_engine]

# choose between mock or real p_chip 
mock_p_chip             = options[:mock_p]

# benchmark options
write_data_gen          = options[:write_data]
run_benchmark           = options[:test]
test_type               = options[:test]
if run_benchmark
  raise ArgumentError, "test \"#{test_type}\" does not exist" unless SpStore::Benchmark::SyntheticBenchmark.benchmark_list.include? test_type
end

################ helper functions ############################

def measure_time 
  start = Time.now
  yield
  puts ( Time.now - start )
end

def display_size(size)
  display = nil
  if size>>10 == 0
    display = "#{size}B"
  elsif size>>20 == 0
    display = "#{size>>10}kB"
  elsif size>>30 == 0
    display = "#{size>>20}MB"
  else
    display = "#{size>>30}GB"
  end
  display
end

################ detailed timing analysis ####################

if options[:detailed_time]
  File.delete options[:detailed_time] if File.exist? options[:detailed_time]
  SpStore::Benchmark::DetailTiming.setup( SpStore::Server::Controller, :read_block, options[:detailed_time] )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Server::Controller, :write_block, options[:detailed_time] )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Mocks::BareController::Session, :read_block, options[:detailed_time] )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Mocks::BareController::Session, :write_block, options[:detailed_time] )
end

################ tree cache hit rate analysis ################

measure_node_hit_rate = options[:node_hit_rate] || options[:node_hit_rate_detail]

if measure_node_hit_rate
  SpStore::Benchmark::NodeCacheHitRate.calculate_hit_rate options[:node_hit_rate_detail]
end

#################### initialization ##########################

# initialize sp_store controller
puts "Initializing SP Store..."
puts " Disk  Size: #{display_size(block_size*block_count)}"
puts "Block  Size: #{display_size(block_size)}"
puts "Block Count: #{block_count}"

sp_store_controller   = nil
measure_time do
  sp_store_controller = SpStore::Benchmark::StoreSetup.sp_store_controller( block_size, block_count, 
                        node_cache_size, session_cache_size, load_store, mock_p_chip, soft_hash_engine )
  puts "Initialization time for sp store (secs):"
end

# initialize bare controller
bare_controller       = nil
measure_time do
  bare_controller     = SpStore::Benchmark::StoreSetup.bare_controller( block_size, block_count, load_store )
  puts "Initialization time for mock store (secs):"
end

# pre-generate write data
measure_time do
  SpStore::Benchmark::StoreSetup.generate_write_data_file block_size, block_count
  puts "Write data pre-generation (secs):"
end if write_data_gen


############### Benchmark Configuration ########################

benchmark_config = SpStore::Benchmark::BenchmarkConfig.new block_size, block_count, measure_node_hit_rate, options[:detailed_time], options[:test_iter],
                                                           SpStore::Benchmark::StoreSetup.disk_directory, sp_store_controller, bare_controller

################### Check Functionality #####################

SpStore::Benchmark::CheckFunctionality.run benchmark_config if options[:check_functionality]

################### Running Benchmark #######################

SpStore::Benchmark::SyntheticBenchmark.run_test( test_type, benchmark_config ) if run_benchmark

################### Delete Existing Store ###################

SpStore::Storage::DiskStore.delete_store if delete_store
SpStore::Mocks::DiskStore.delete_store   if delete_store
