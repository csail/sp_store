# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Software (untrusted) implementation of the P chip's node cache.
class SoftNodeCache
  # Instantiates a software model of the P chip's node cache module.
  def initialize(p_key, ca_public_key, soft_session_cache)
    @p_key = p_key
    @ca_pubkey = ca_public_key
    @key_cache = soft_session_cache
  end
  
  def certify(session_id, nonce_cache_entry)
    hmac_key = @key_cache.session_key session_id
    _certify hmac_key, node_cache_entry
  end
  
  def update(session_id, nonce, update_path, data_hash)
    hmac_key = @key_cache.session_key session_id
    _update hmac_key, node_cache_entry
  end

  def load(cache_entry, node_id, node_hash, old_parent_entry)
    
  end

  def _certify(hmac_key, nonce_cache_entry)
    session_key = @key_cache.session_key session_id
    _certify session_key, node_cache_entry
  end
  private :_certify
  
  def _update(hmac_key, nonce, update_path, data_hash)
    hmac_key = @key_cache.session_key session_id
    _update session_key, node_cache_entry
  end
  private :_update
end  # class SpStore::PChip::SoftNodeCache
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
