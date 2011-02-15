# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

class SessionTable
  def initialize(capacity, endorsement_key)
    @capacity = capacity
    @ekey = endorsement_key
    @keys = Array.new capacity
  end
  
  attr_reader :capacity
  
  def open_session(session_id, encrypted_session_key)
    
  end
  
  def close_session(session_id)
    
  end
  
  def certify(session_id, nonce, node_id, node_hash)
    
  end
  
  def verify_update(session_id, nonce, node_id, node_hash)
    
  end
end  # class SpStore::PChip::SessionTable
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
