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
    @allocator = SessionAllocator.new @p.session_table_size
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

  attr_reader :endorsement_certificate

  def session(encrypted_session_key)
    session_id = @allocator.new_id
    Session.new 
  end

  # :nodoc: called by Session
  def read_block(session_id, block_id, nonce)
    
  end

  # :nodoc: called by Session
  def write_block(session_id, block_id, data, nonce)
    
  end
end  # class SpStore::Server::Controller

# :nodoc: namespace
class Controller

class Session
  def initialize(session_id, io_logic)
    @session_id = session_id
    @io_logic = io_logic
  end

  def close
  end
  
  def block_size
    
  end
  
  def blocks
    
  end
  
  def read_block(block_id, nonce)
    io_logic.read_block @session_id, block_id, nonce
  end

  def write_block(block_id, data, nonce)
    io_logic.write_block @session_id, block_id, nonce
  end
end  # class SpStore::Server::Controller::Session

end  # namespace SpStore::Server::Controller

end  # namespace SpStore::Server

end  # namespace SpStore
