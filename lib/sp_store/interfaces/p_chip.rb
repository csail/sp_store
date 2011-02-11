# :nodoc: namespace
module SpStore
  
# API implemented by a P chip (powerful processor without non-volatile state).
module PChip
  # The number of data blocks (hash tree leaves) that supported by this P chip.
  def capacity
    
  end
  
  # The first step of the S-P boot sequence.
  #
  # This method can only be called once, right after the P chip is powered on.
  # It should be followed by a call to boot_finish.
  #
  # Args:
  #   puf_syndrome:: the information needed to recover the P chip's symmetric
  #                  key out of its PUF
  #
  # Returns a randomly generated nonce, and the nonce's HMAC, keyed under the
  # P chip's symmetric key.
  #
  # Raises:
  #   RuntimeError:: if boot_start was already called
  #   RuntimeError:: if the HMAC doesn't match the system state (root_hash)
  def boot_start(puf_syndrome)
    
  end
  
  # The last step of the S-P boot sequence.
  #
  # This method can only be called once, after boot_start has been called. After
  # the method completes, the P chip can serve requests.
  #
  # Args:
  #   root_hash:: the storage root key
  #   state_hmac:: HMAC over the P chip's nonce and root hash, keyed with the
  #                P chip's symmetric key
  #   endorsement_key:: the private endorsement key for the S-P chip pair,
  #                     encrypted with the P chip's symmetric key
  #
  # Returns self.
  #
  # Raises:
  #   RuntimeError:: if boot_finish was alredy called, or boot_start wasn't
  #                  called yet
  #   RuntimeError:: if the HMAC doesn't match the system state (root_hash)
  def boot_finish(root_hash, state_hmac, endorsement_key)
    
  end
  
  # Establishes a session between a S-P store client and the P chip.
  #
  # Args:
  #   session_id:: a low number specifying the key slot used by this session
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the S-P chip pair's' public
  #                           Endorsement Key
  #
  # Returns the HMAC of the given nonce under the session key.
  def open_session(session_id, encrypted_session_key)
    session_key = Crypto.pki_decrypt @endorsement_key[:private],
                                     encrypted_session_key
    @session_keys[session_id] = session_key
    Crypto.hmac session_key, nonce
  end
  
  # Tears down a session between a trusted-storage client and the P chip.
  #
  # Returns self.
  def close_session(session_id)
    @session_keys.delete session_id
    self
  end
  
  # Loads a hash tree node into a cache entry.
  #
  # Args:
  #   cache_entry:: the number of the cache entry to load (0-based)
  #   node_id:: the node ID (not leaf ID) of the node to be loaded
  #   node_hash:: the node's hash
  #   old_parent_entry:: the number of the cache entry holding the parent of the
  #                      node held by this cache entry before the load operation
  #
  # Raises:
  #   ArgumentError:: entry or old_parent_entry point to invalid cache entries
  #   ArgumentError:: node_id is an invalid hash tree node number
  #   ArgumentError:: entry is validated, and old_parent_entry does not
  #                   store the parent node of entry's node
  #   ArgumentError:: entry is validated, and its node has at least one child
  #                   stored in a validated cache entry
  #
  # A node's entry can only be overwritten if none of the node's children is
  # cached. When loading a new node in an entry, the old node's parent is
  # updated to reflect that its child is missing. The entry's verified flag is
  # cleared after it is a assigned a new value.
  def load(cache_entry, node_id, node_hash, old_parent_entry)
    
  end

  
  # Certifies a block's contents.
  #
  # Args:
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   cache_entry:: the cache line holding the block's hash (0-based)
  #
  # Returns: HMAC(session key, nonce || block number || block hash)
  def certify(session_id, nonce, cache_entry)
    
  end
  
  # Updates a block's contents.
  #
  # Args:
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   update_path:: sequence of cache entries to be updated / checked during the
  #                 update process; even positions are the cache line numbers of
  #                 the nodes on the path between the leaf and the tree root,
  #                 and odd positions are the cache line numbers of the siblings
  #                 of the nodes in the corresponding even posittions
  #   data_hash:: the hash of the block's new contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def update(session_id, nonce, update_path, data_hash)
    
  end
  
  # Computes the hash for a block of data.
  #
  # Args:
  #   data:: the data block to be hashed
  #
  # Returns a cryptographic hash of the data block.
  def hash_block(data)
    
  end
end  # class SpStore::PChip

end  # namespace SpStore
