
# :nodoc: namespace
module SpStore 
  
# :nodoc: namespace
module Benchmark
  
class BenchmarkConfig

  def initialize( block_size, block_count, node_hit_rate = false, detailed_timing = false, test_iter, disk_directory, sp_controller, bare_controller )
    @block_size       = block_size
    @block_count      = block_count
    @node_hit_rate    = node_hit_rate
    @detailed_timing  = detailed_timing
    @test_iter        = test_iter    
    @write_disk_path  = File.join( disk_directory, "sp_store_write_data" )
    @disk_data_file   = File.join @write_disk_path, "write_data"
    @sp_controller    = sp_controller
    @bare_controller  = bare_controller
    @node_cache_reset = true
  end
  attr_reader :block_size, :block_count, :node_hit_rate, :detailed_timing, :write_disk_path, :disk_data_file, :sp_controller, :bare_controller
  attr_accessor :node_cache_reset


end # namespace SpStore::Benchmark::BenchmarkConfig

end # namespace SpStore::Benchmark

end # namespace SpStore