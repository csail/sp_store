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
   options[:write_data] = false   
   opts.on( '--write-data', 'Pre-generate random bytes for block write' ) do
     options[:write_data] = true
   end
   options[:detailed_time] = false   
   opts.on( '--detailed-time', 'Detailed timing analysis' ) do
     options[:detailed_time] = true
   end      
   options[:test] = nil
   opts.on( '-t', '--test TEST-NAME', 'Run benchmark TEST-NAME' ) do |test_type|
     options[:test] = test_type
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

block_size              = 2**options[:block_size]  if options[:block_size]  && options[:init] && options[:block_size]!= 0
block_count             = 2**options[:block_count] if options[:block_count] && options[:init] && options[:block_count]!= 0
node_cache_size         = 2**options[:cache_size]  if options[:cache_size]  && options[:cache_size]!= 0

load_store              = !options[:init]
delete_store            = options[:delete]

# choose between mock or real p_chip 
mock_p_chip             = options[:mock_p]

# benchmark options
write_data_gen          = options[:write_data]
run_benchmark           = options[:test]
test_type               = options[:test]
if run_benchmark
  raise ArgumentError, "test \"#{test_type}\" does not exist" unless SpStore::Benchmark::SyntheticBenchmark.method_defined? test_type
end

################ helper functions ############################

def measure_time 
  start = Time.now
  yield
  puts ( Time.now - start )
end

################ detailed timing analysis ####################

if options[:detailed_time]
  SpStore::Benchmark::DetailTiming.setup( SpStore::Server::Controller, :read_block )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Server::Controller, :write_block )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Mocks::BareController::Session, :read_block )
  SpStore::Benchmark::DetailTiming.setup( SpStore::Mocks::BareController::Session, :write_block )
end

#################### initialization ##########################

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

eval "benchmark.#{test_type}" if run_benchmark

################### Delete Existing Store ###################

SpStore::Storage::DiskStore.delete_store if delete_store
SpStore::Mocks::DiskStore.delete_store   if delete_store
