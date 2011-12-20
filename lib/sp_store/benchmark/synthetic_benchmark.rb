require 'openssl'

# :nodoc: namespace
module SpStore 
  
# :nodoc: namespace
module Benchmark
  
# generates access patterns for benchmarking
class SyntheticBenchmark
  def initialize( block_size, block_count, node_hit_rate = false, disk_directory, sp_controller, bare_controller )
    @block_size       = block_size
    @block_count      = block_count
    @node_hit_rate    = node_hit_rate
    @write_disk_path  = File.join( disk_directory, "sp_store_write_data" )
    @sp_controller    = sp_controller
    @bare_controller  = bare_controller
    @node_cache_reset = true
  end
  
  # print node cache hit rate results then reset
  def output_node_hit_rate
    cache_controller = @sp_controller.instance_variable_get(:@hash_tree_controller)
    node_to_load     = cache_controller.total_node_to_load
    node_needed      = cache_controller.total_node_needed
    puts "node cache hit rate = 1 - #{node_to_load}/#{node_needed} = #{(1-node_to_load.to_f/node_needed)*100}%"
    cache_controller.reset_hit_info
  end
  
  # generates random data for write testing
  def generate_write_data_file
    #initialize disk
    Dir.mkdir(@write_disk_path, 0777) unless Dir.exist? @write_disk_path
    #initialize disk data
    File.open(disk_data_file(@write_disk_path), 'wb') do |file|
      (0...@block_count).each do
         file.write OpenSSL::Random.random_bytes(@block_size)
      end
    end
  end
  
  # Path to write_data file
  def disk_data_file(disk_path)
     File.join disk_path, 'write_data'
  end

  # initialize session
  def create_session(controller)
    ecert         = controller.endorsement_certificate
    session_key   = SpStore::Crypto.hmac_key
    encrypted_key = SpStore::Crypto.pki_encrypt ecert.public_key, session_key
    controller.session encrypted_key
  end
  
  # initialize session with given hmac key
  def create_session_with_key(controller, key)
    ecert         = controller.endorsement_certificate
    encrypted_key = SpStore::Crypto.pki_encrypt ecert.public_key, key
    controller.session encrypted_key
  end

  # run all benchmarks
  def test_all
    read_only_cont
    read_only_period
    read_only_random
    write_only_cont
    write_only_period
    write_only_random
    random_read_write    
  end

  # benchmark test: check functionality 
  def check_functionality
    puts "Running test: check program functionality"
    session_key  = SpStore::Crypto.hmac_key
    session1     = create_session_with_key @bare_controller, session_key
    session2     = create_session_with_key @sp_controller, session_key
    r = Random.new(1100)
    p = 0.5
    File.open(disk_data_file(@write_disk_path), 'rb') do |file|     
      (0...@block_count).each do
        is_read  = r.rand < p
        block_id = r.rand(@block_count)
        nonce    = SpStore::Crypto.nonce
        if is_read         
          data1, hmac1 = session1.read_block block_id, nonce
          data2, hmac2 = session2.read_block block_id, nonce
          golden_bare_hmac = SpStore::Crypto.hmac_for_block(block_id, data1, nonce, session_key)
          golden_sp_hmac   = SpStore::Crypto.hmac_for_block(block_id+@block_count, data2, nonce, session_key)          
          raise RuntimeError, "read block #{block_id} failed" unless data1 == data2 && hmac1 == golden_bare_hmac && hmac2 == golden_sp_hmac
        else
          file.seek(block_id*@block_size, IO::SEEK_SET)
          write_data = file.read(@block_size)
          hmac1 = session1.write_block block_id, write_data, nonce
          hmac2 = session2.write_block block_id, write_data, nonce
          golden_bare_hmac = SpStore::Crypto.hmac_for_block(block_id, write_data, nonce, session_key)
          golden_sp_hmac   = SpStore::Crypto.hmac_for_block(block_id+@block_count, write_data, nonce, session_key)   
          raise RuntimeError, "write block #{block_id} failed" unless hmac1 == golden_bare_hmac && hmac2 == golden_sp_hmac
        end
      end
    end
    puts "Functionality Correct!"
    @bare_controller.save_hashes
    @sp_controller.save_hashes
  end 

  # benchmark test: read whole disk continuously 
  def read_only_cont
    puts "Running test: read whole disk continuously"
    iter_num     = 2
    puts "For bare controller:"
    session = create_session @bare_controller
    (0...iter_num).each do
      measure_time do
        (0...@block_count).each do |block_id|
          session.read_block block_id, SpStore::Crypto.nonce
        end
      end
    end
    puts "For sp_store controller:"
    session = create_session @sp_controller
    (0...iter_num).each do
      @sp_controller.reset_node_cache unless @node_cache_reset 
      measure_time do
        (0...@block_count).each do |block_id|
          session.read_block block_id, SpStore::Crypto.nonce
        end
      end
      output_node_hit_rate if @node_hit_rate
      @node_cache_reset = false
    end
  end 

  # benchmark test: read a chunk of data periodically
  def read_only_period
    puts "Running test: read a chunk of data periodically"
    iter_num     = 2**5
    chunk_length = 2**6
    puts "For bare controller:"
    session = create_session @bare_controller
    measure_time do
      (0...iter_num).each do
         (0...chunk_length).each do |block_id|
           session.read_block block_id, SpStore::Crypto.nonce
         end
      end
    end  
    puts "For sp_store controller:"
    session = create_session @sp_controller
    @sp_controller.reset_node_cache unless @node_cache_reset 
    measure_time do
      (0...iter_num).each do
         (0...chunk_length).each do |block_id|
           session.read_block block_id, SpStore::Crypto.nonce
         end
      end
    end
    output_node_hit_rate if @node_hit_rate
    @node_cache_reset = false
  end 


  # benchmark test: write whole disk continuously   
  def write_only_cont
    puts "Running test: write whole disk continuously"
    iter_num     = 2
    
    File.open(disk_data_file(@write_disk_path), 'rb') do |file|
        
      puts "For bare controller:"
      session = create_session @bare_controller
      (0...iter_num).each do
        measure_time do
          (0...@block_count).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
      end
      @bare_controller.save_hashes

      puts "For sp_store controller:"
      session = create_session @sp_controller
      (0...iter_num).each do
        @sp_controller.reset_node_cache unless @node_cache_reset
        measure_time do
          (0...@block_count).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
        output_node_hit_rate if @node_hit_rate
        @node_cache_reset = false
      end
      # save hash_tree
      @sp_controller.save_hashes     

    end
  end
  
  # benchmark test: write a chunk of data periodically
  def write_only_period
    puts "Running test: write a chunk of data periodically"
    iter_num     = 2**5
    chunk_length = 2**6
    
    File.open(disk_data_file(@write_disk_path), 'rb') do |file|
        
      puts "For bare controller:"

      session = create_session @bare_controller
      measure_time do
        (0...iter_num).each do
          (0...chunk_length).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
      end
      @bare_controller.save_hashes
      
      puts "For sp_store controller:"
      session = create_session @sp_controller
      @sp_controller.reset_node_cache unless @node_cache_reset
      measure_time do
        (0...iter_num).each do
          (0...chunk_length).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
      end
      output_node_hit_rate if @node_hit_rate
      @node_cache_reset = false
      # save hash_tree
      @sp_controller.save_hashes
    end
  end  
  
  # benchmark test: read randomly chosen blocks
  def read_only_random
    puts "Running test: randomly read data blocks"
    random_read_write(1.0)
  end

  # benchmark test: write randomly chosen blocks
  def write_only_random
    puts "Running test: randomly write data blocks"
    random_read_write(0.0)    
  end

  # benchmark test: randomly read or write (with read probability = p )
  def random_read_write(p = 0.5)
    puts "Running test: randomly read and write data blocks"
    iter_num = 2
    seed     = 123
    File.open(disk_data_file(@write_disk_path), 'rb') do |file|        
      puts "For bare controller:"
      session = create_session @bare_controller
      (0...iter_num).each do
        r = Random.new(seed)
        measure_time do
          (0...@block_count).each do
            is_read  = r.rand < p
            block_id = r.rand(@block_count)
            if is_read
              session.read_block block_id, SpStore::Crypto.nonce
            else
              file.seek(block_id*@block_size, IO::SEEK_SET)
              session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
            end
          end
        end
      end
      @bare_controller.save_hashes
      
      puts "For sp_store controller:"
      session = create_session @sp_controller
      (0...iter_num).each do
        r = Random.new(seed)
        @sp_controller.reset_node_cache unless @node_cache_reset
        measure_time do
          (0...@block_count).each do
            is_read  = r.rand < p
            block_id = r.rand(@block_count)
            if is_read
              session.read_block block_id, SpStore::Crypto.nonce
            else
              file.seek(block_id*@block_size, IO::SEEK_SET)
              session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
            end
          end
        end
        output_node_hit_rate if @node_hit_rate
        @node_cache_reset = false
      end
      # save hash_tree
      @sp_controller.save_hashes
    end
  end  

  # measures execution time
  def measure_time 
    start = Time.now
    yield
    puts "Execution time (secs): #{Time.now-start}"
  end

end # namespace SpStore::Benchmark::SyntheticBenchmark

end # namespace SpStore::Benchmark

end # namespace SpStore