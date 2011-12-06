require 'openssl'

# :nodoc: namespace
module SpStore 
  
# :nodoc: namespace
module Benchmark
  
# generates access patterns for benchmarking
class SyntheticBenchmark
  def initialize( block_size, block_count, disk_directory, sp_controller, bare_controller )
    @block_size      = block_size
    @block_count     = block_count
    @write_disk_path = File.join( disk_directory, "sp_store_write_data" )
    @sp_controller   = sp_controller
    @bare_controller = bare_controller
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
      measure_time do
        (0...@block_count).each do |block_id|
          session.read_block block_id, SpStore::Crypto.nonce
        end
      end
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
    measure_time do
      (0...iter_num).each do
         (0...chunk_length).each do |block_id|
           session.read_block block_id, SpStore::Crypto.nonce
         end
      end
    end 
  end 


  # benchmark test: write whole disk continuously   
  def write_only_cont
    puts "Running test: write whole disk continuously"
    iter_num     = 3
    
    File.open(disk_data_file(@write_disk_path), 'rb') do |file|
  
      puts "For sp_store controller:"
      session = create_session @sp_controller
      (0...iter_num).each do
        measure_time do
          (0...@block_count).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
      end
      # save hash_tree
      @sp_controller.save_hash_tree  
        
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
      @bare_controller.save_disk_hash
      

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
      @bare_controller.save_disk_hash
      
      puts "For sp_store controller:"
      session = create_session @sp_controller
      measure_time do
        (0...iter_num).each do
          (0...chunk_length).each do |block_id|
            file.seek(block_id*@block_size, IO::SEEK_SET)
            session.write_block block_id, file.read(@block_size), SpStore::Crypto.nonce
          end
        end
      end
      # save hash_tree
      @sp_controller.save_hash_tree
    end
  end  

  # benchmark test: randomly read or write (with read probability = p )
  def random_read_write
    puts "Running test: random read and write data blocks"
    iter_num = 3
    p        = 0.5
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
      @bare_controller.save_disk_hash
      
      puts "For sp_store controller:"
      session = create_session @sp_controller
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
      # save hash_tree
      @sp_controller.save_hash_tree
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