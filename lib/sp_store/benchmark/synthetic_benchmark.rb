# :nodoc: namespace
module SpStore 
  
# :nodoc: namespace
module Benchmark

# run synthetic benchmarking
module SyntheticBenchmark

  def self.benchmark_list
    [ "read_only_cont",
      "read_only_period",
      "read_only_random",
      "write_only_cont",
      "write_only_period",
      "write_only_random",
      "random_read_write",
      "test_all"  ]
  end

  def self.run_test(test, bmconfig)
    if test == "test_all"
      run_test_all bmconfig
      return
    end    
    if test =~ /random/
      if test =~ /write_only/
        read_prob = 0.0 
      elsif test =~ /read_only/
        read_prob = 1.0
      else
        read_prob = 0.5
      end
      if bmconfig.test_iter
        bm = RandomAccess.new bmconfig, read_prob, bmconfig.test_iter.to_i
      else
        bm = RandomAccess.new bmconfig, read_prob 
      end
    else
      classname = test.gsub(/^.|(_.)/) {|s| s.upcase[-1,1]}
      clazz = Kernel.const_get("SpStore").const_get("Benchmark").const_get("SyntheticBenchmark").const_get(classname)
      if bmconfig.test_iter
        bm = clazz.new bmconfig, bmconfig.test_iter.to_i
      else
        bm = clazz.new bmconfig
      end
    end
    bm.run   
  end
  
  def self.run_test_all(bmconfig)
    benchmark_list[0...-1].each do |bm_name|
      run_test(bm_name, bmconfig)
    end
  end

# generates access patterns for benchmarking
# base class
class SyntheticBenchmarkBase
  # store benchmark configurations and test iteration times 
  def initialize( bmconfig, iter_num = 1 )
    @bmconfig      = bmconfig
    @test_iter_num = iter_num
  end

  # should be overwritten by subclasses
  def benchmark_header
    "\nRunning test:"
  end
  
  def run
    output_detail_timing_info benchmark_header if @bmconfig.detailed_timing
    puts benchmark_header
    run_with_controller "bare_controller" 
    run_with_controller "sp_controller"
    save_hashes_for_write
  end
   
  def output_detail_timing_info(info)
    File.open(@bmconfig.detailed_timing, "a") do |dfile|
      dfile.puts info
    end
  end
  
  def run_with_controller(controller_type)
    puts "For #{controller_type}:"
    session = create_session @bmconfig.instance_variable_get("@#{controller_type}")
    (0...@test_iter_num).each do
      output_detail_timing_info "For #{controller_type}:" if @bmconfig.detailed_timing
      if controller_type == "sp_controller"
        @bmconfig.sp_controller.reset_node_cache unless @bmconfig.node_cache_reset
      end
      reset_random_seed
      measure_time do
        run_one_test session
      end
      if controller_type == "sp_controller"
        output_node_hit_rate if @bmconfig.node_hit_rate
        @bmconfig.node_cache_reset = false
      end
    end
  end 
  
  # initialize session
  def create_session(controller)
    ecert         = controller.endorsement_certificate
    session_key   = SpStore::Crypto.hmac_key
    encrypted_key = SpStore::Crypto.pki_encrypt ecert.public_key, session_key
    controller.session encrypted_key
  end
    
  # should be overwritten by subclasses
  def run_one_test(session)
    
  end

  # remain empty for read only benchmarks  
  def save_hashes_for_write
    
  end

  # remain empty for non-random benchmarks  
  def reset_random_seed
    
  end
  
  # measures execution time
  def measure_time 
    start = Time.now
    yield
    puts "Execution time (secs): #{Time.now-start}"
  end  
  
  # print node cache hit rate results then reset
  def output_node_hit_rate
    cache_controller = @bmconfig.sp_controller.instance_variable_get(:@hash_tree_controller)
    node_to_load     = cache_controller.total_node_to_load
    node_needed      = cache_controller.total_node_needed
    puts "node cache hit rate = 1 - #{node_to_load}/#{node_needed} = #{(1-node_to_load.to_f/node_needed)*100}%"
    cache_controller.reset_hit_info
  end  
  
end # namespace SpStore::Benchmark::SyntheticBenchmark::SyntheticBenchmarkBase

class ReadOnlyCont < SyntheticBenchmarkBase
  def initialize( bmconfig, iter_num = 2 )
    @bmconfig      = bmconfig
    @test_iter_num = iter_num
  end
  def benchmark_header
    super+" read whole disk continuously"
  end
  def run_one_test(session)
    (0... @bmconfig.block_count).each do |block_id|
      session.read_block block_id, SpStore::Crypto.nonce
    end
  end
end # namespace SpStore::Benchmark::SyntheticBenchmark::ReadOnlyCont

class ReadOnlyPeriod < SyntheticBenchmarkBase
  def benchmark_header
    super+" read a chunk of data periodically"
  end
  def run_one_test(session)    
    iter_num     = 1<<5
    chunk_length = ( (1<<6)*((1<<20).to_f/@bmconfig.block_size) ).to_i
    (0...iter_num).each do
       (0...chunk_length).each do |block_id|
         session.read_block block_id, SpStore::Crypto.nonce
       end
    end
  end
end # namespace SpStore::Benchmark::SyntheticBenchmark::ReadOnlyPeriod

class WriteOnlyCont < SyntheticBenchmarkBase
  def initialize( bmconfig, iter_num = 2 )
    @bmconfig      = bmconfig
    @test_iter_num = iter_num
  end
  def benchmark_header
    super+" write whole disk continuously"
  end
  def run_one_test(session)
    File.open(@bmconfig.disk_data_file, 'rb') do |file|
      (0... @bmconfig.block_count).each do |block_id|
         file.seek(block_id*@bmconfig.block_size, IO::SEEK_SET)
         session.write_block block_id, file.read(@bmconfig.block_size), SpStore::Crypto.nonce
      end
    end
  end
  def save_hashes_for_write
    @bmconfig.bare_controller.save_hashes
    @bmconfig.sp_controller.save_hashes 
  end  
end # namespace SpStore::Benchmark::SyntheticBenchmark::WriteOnlyCont

class WriteOnlyPeriod < SyntheticBenchmarkBase
  def benchmark_header
    super+" write a chunk of data periodically"
  end
  def run_one_test(session)
    iter_num     = 1<<5
    chunk_length = ( (1<<6)*((1<<20).to_f/@bmconfig.block_size) ).to_i
    File.open(@bmconfig.disk_data_file, 'rb') do |file|
      (0...iter_num).each do
         (0...chunk_length).each do |block_id|
           file.seek(block_id*@bmconfig.block_size, IO::SEEK_SET)
           session.write_block block_id, file.read(@bmconfig.block_size), SpStore::Crypto.nonce
         end
      end    
    end
  end
  def save_hashes_for_write
    @bmconfig.bare_controller.save_hashes
    @bmconfig.sp_controller.save_hashes 
  end  
end # namespace SpStore::Benchmark::SyntheticBenchmark::WriteOnlyPeriod

class RandomAccess < SyntheticBenchmarkBase
  def initialize( bmconfig, read_prob = 0.5, iter_num = 2 )
    @bmconfig      = bmconfig
    @test_iter_num = iter_num
    @read_prob     = read_prob
    @seed          = 1223
  end
  def benchmark_header
    if @read_prob == 0.0
      super+" randomly write data blocks"       
    elsif @read_prob == 1.0
      super+" randomly read data blocks"
    else
      super+" randomly read and write data blocks"    
    end
  end
  def run_one_test(session)
    random_access_size = 1<<20
    blocks_per_access  = random_access_size/@bmconfig.block_size
    blocks_per_access  = 1 if blocks_per_access == 0
    File.open(@bmconfig.disk_data_file, 'rb') do |file|
      (0...((@bmconfig.block_count)/blocks_per_access)).each do
        is_read  = @rng.rand < @read_prob
        block_id = @rng.rand(@bmconfig.block_count-blocks_per_access+1)
        if is_read
          (0...blocks_per_access).each { |inc| session.read_block block_id+inc, SpStore::Crypto.nonce }
        else
          (0...blocks_per_access).each do |inc|
            file.seek((block_id+inc)*@bmconfig.block_size, IO::SEEK_SET)
            session.write_block block_id+inc, file.read(@bmconfig.block_size), SpStore::Crypto.nonce
          end
        end
      end
    end
  end
  def save_hashes_for_write
    @bmconfig.bare_controller.save_hashes
    @bmconfig.sp_controller.save_hashes
  end
  def reset_random_seed
    @rng = Random.new(@seed)
  end
end # namespace SpStore::Benchmark::SyntheticBenchmark::RandomAccess

end # namespace SpStore::Benchmark::SyntheticBenchmark

end # namespace SpStore::Benchmark

end # namespace SpStore