# :nodoc: namespace
module SpStore
  
# :nodoc: namespace
module Server

# Glues all the S-P store components together.
class Controller
  def initialize(storage, s_chip, p_chip)
    @storage = storage
    @s = s_chip
    @p = p_chip
    boot_sp_pair
    @allocator = SessionAllocator.new @p.session_cache
    @hash_tree_controller = HashTreeController.new @p.node_cache, @storage.hash_tree
  end
  
  # Boots the S-P chip pair that forms the system's TCB.
  def boot_sp_pair
    @endorsement_certificate = @s.endorsement_certificate
    puf_syndrome = @s.puf_syndrome
    encrypted_nonce, nonce_hmac =
        @p.boot_logic.boot_start puf_syndrome, @endorsement_certificate
    root_hash, state_hmac, endorsement_key = @s.boot encrypted_nonce, nonce_hmac
    @p.boot_logic.boot_finish root_hash, state_hmac, endorsement_key
  end

  attr_reader :endorsement_certificate, :storage

  def session(encrypted_session_key)
    session_id = @allocator.new_id encrypted_session_key
    Session.new session_id, self
  end

  # :nodoc: called by Session
  def close_session(session_id)
    @allocator.release_id session_id
  end  

  # :nodoc: called by Session
  def read_block(session_id, block_id, nonce)
    _check_block_id block_id
    session_cache_entry = @allocator.session_cache_entry session_id
    data = @storage.read_block block_id
    hmac = @hash_tree_controller.sign_read_block block_id, session_cache_entry, nonce   
    return data, hmac
  end

  # :nodoc: called by Session
  def write_block(session_id, block_id, data, nonce)
    _check_block_id block_id
    session_cache_entry = @allocator.session_cache_entry session_id
    @storage.write_block block_id, data
    #data_hash = @p.hash_engine.hash_block data
    data_hash  = SpStore::Crypto.crypto_hash data
    @hash_tree_controller.sign_write_block block_id, data_hash, session_cache_entry, nonce
  end
  
  # :nodoc
  def _check_block_id(block_id)
    raise ArgumentError, "Negative block #{block_id}" if block_id < 0
    if @storage.blocks <= block_id
      raise ArgumentError, "Block #{block_id} exceeds store size #{@storage.blocks}"
    end
  end
  private :_check_block_id  
  
end  # class SpStore::Server::Controller

# :nodoc: namespace
class Controller

class Session
  def initialize(session_id, io_logic)
    @session_id = session_id
    @io_logic = io_logic
  end

  def close
    @io_logic.close_session @session_id
  end
  
  def block_size
    @io_logic.storage.block_size
  end
  
  def blocks
    @io_logic.storage.blocks
  end
  
  def read_block(block_id, nonce)
    @io_logic.read_block @session_id, block_id, nonce
  end

  def write_block(block_id, data, nonce)
    @io_logic.write_block @session_id, block_id, data, nonce
  end
  
end  # class SpStore::Server::Controller::Session

end  # namespace SpStore::Server::Controller

end  # namespace SpStore::Server

end  # namespace SpStore
