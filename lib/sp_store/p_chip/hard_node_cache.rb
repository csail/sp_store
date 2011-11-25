# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Interface with hardware implementation of P chip's node cache (FPGA)
class HardNodeCache
  # Instantiates a P chip's node cache module 
  # serving as the interface with the real P chip's node cache on FPGA
  def initialize(capacity, leaf_count, soft_session_cache)
    @capacity = capacity
    @leaf_count = leaf_count
    @key_cache = soft_session_cache
  end
  
  attr_reader :capacity, :leaf_count
  
  def certify(session_id, nonce, cache_entry)
    hmac_key = @key_cache.session_key session_id
  end
  
  def update(update_path, data_hash)

  end

  def load(cache_entry, node_id, node_hash, old_parent_entry)

  end

  def verify(parent, left_child, right_child)

  end
  
  Helpers = SpStore::Merkle::HashTreeHelper
  
end  # class SpStore::PChip::HardNodeCache
  
end  # namespace SpStore::PChip
  
end  # namespace SpStore
