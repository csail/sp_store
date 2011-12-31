require 'openssl'

# :nodoc: namespace
module SpStore 
# :nodoc: namespace
module Benchmark
  
# check functionality of the whole system
module CheckFunctionality
  
  # initialize session with given hmac key
  def self.create_session_with_key(controller, key)
    ecert         = controller.endorsement_certificate
    encrypted_key = SpStore::Crypto.pki_encrypt ecert.public_key, key
    controller.session encrypted_key
  end
  
  def self.run(bmconfig)
    puts "Running test: check program functionality"
    session_key  = SpStore::Crypto.hmac_key
    session1     = create_session_with_key bmconfig.bare_controller, session_key
    session2     = create_session_with_key bmconfig.sp_controller, session_key
    r = Random.new(1100)
    p = 0.5
    File.open(bmconfig.disk_data_file, 'rb') do |file|     
      (0...bmconfig.block_count).each do
        is_read  = r.rand < p
        block_id = r.rand(bmconfig.block_count)
        nonce    = SpStore::Crypto.nonce
        if is_read         
          data1, hmac1 = session1.read_block block_id, nonce
          data2, hmac2 = session2.read_block block_id, nonce
          golden_bare_hmac = SpStore::Crypto.hmac_for_block(block_id, data1, nonce, session_key)
          golden_sp_hmac   = SpStore::Crypto.hmac_for_block(block_id+bmconfig.block_count, data2, nonce, session_key)          
          raise RuntimeError, "read block #{block_id} failed" unless data1 == data2 && hmac1 == golden_bare_hmac && hmac2 == golden_sp_hmac
        else
          file.seek(block_id*bmconfig.block_size, IO::SEEK_SET)
          write_data = file.read(bmconfig.block_size)
          hmac1 = session1.write_block block_id, write_data, nonce
          hmac2 = session2.write_block block_id, write_data, nonce
          golden_bare_hmac = SpStore::Crypto.hmac_for_block(block_id, write_data, nonce, session_key)
          golden_sp_hmac   = SpStore::Crypto.hmac_for_block(block_id+bmconfig.block_count, write_data, nonce, session_key)   
          raise RuntimeError, "write block #{block_id} failed" unless hmac1 == golden_bare_hmac && hmac2 == golden_sp_hmac
        end
      end
    end
    puts "Functionality Correct!"
    bmconfig.bare_controller.save_hashes
    bmconfig.sp_controller.save_hashes
  end

end # namespace SpStore::Benchmark::CheckFunctionality

end # namespace SpStore::Benchmark

end # namespace SpStore