# :nodoc: namespace
module SpStore
  
# API implemented by a P chip (powerful processor without non-volatile state).
module PChip
  # Interface to the P chip's session key cache, which implements SessionCache.
  def session_cache
    
  end
  
  # Interface to the P chip's boot logic, which implements BootLogic.
  def boot_logic
    
  end
  
  # Interface to the P chip's tree node cache, which implements NodeCache.
  def node_cache
    
  end
  
  # Computes the hash for a block of data.
  #
  # This is the interface to the P chip's data hash block.
  #
  # Args:
  #   data:: the data block to be hashed
  #
  # Returns a cryptographic hash of the data block.
  def hash_block(data)
    
  end
end  # module SpStore::PChip


# :nodoc: namespace
module PChip

# API implemented by the P chip's boot logic module.
module BootLogic
  # Resets the P chip to the initial power-up state.
  #
  # After this call, the chip must be taken through the S-P boot sequence, by
  # calling boot_start and boot_finish.
  def reset
    
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
  # Returns a randomly generated nonce encrypted with the P chip's symmetric
  # key, and the nonce's HMAC, keyed under the P chip's symmetric key.
  #
  # Raises:
  #   RuntimeError:: if boot_start was already called
  #   RuntimeError:: if the PUF syndrome is invalid
  def boot_start(puf_syndrome, endorsement_certificate)
    
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
  #   encrypted_endorsement_key:: the private endorsement key for the S-P chip
  #                               pair, encrypted with the P chip symmetric key
  #
  # Returns self.
  #
  # Raises:
  #   RuntimeError:: if boot_finish was already called, or boot_start wasn't
  #                  called yet
  #   RuntimeError:: if the HMAC doesn't match the system state (root_hash)
  def boot_finish(root_hash, state_hmac, endorsement_key)
    
  end
end  # module SpStore::PChip::BootLogic

# API implemented by the P chip's session key cache.
#
# The cache is secure volatile memory that stores HMAC keys for the S-P store's
# user sessions. The cache size will likely be smaller than the maximum number
# of concurrent sessions.
module SessionCache
  # Maxinum number of session keys that can be cached simultaneously.
  def capacity
    
  end
  
  # Processes a user-supplied encrypted session key to accelerate loads.
  #
  # Args:
  #   encrypted_session_key:: the client-generated session HMAC key, encrypted
  #                           under the S-P chip pair's' public Endorsement Key
  #
  # Returns the session HMAC key, encrypted with the P chip's session encryption
  # key, which is randomly generated at boot time.
  def process_key(encrypted_session_key)
    
  end
  
  # Loads a session table entry.
  #
  # Args:
  #   session_id:: a low number specifying the key slot used by this session
  #   processed_session_key:: the result of calling process_key on the
  #                           client-supplied encrypted session HMAC key
  def load(session_id, processed_session_key)
    
  end
end  # module SpStore::PChip::SessionCache

# API implemented by the P chip's node cache.
module NodeCache
  # Number of cache lines (entries) in this P chip's node cache.
  #
  # This will not change after the P chip is manufactured.
  def capacity
    
  end
  
  # The number of data blocks (hash tree leaves) supported by this node cache.
  #
  # This will not change after the P chip is manufactured.
  def leaf_count
    
  end

  # Loads a hash tree node into a cache entry.
  #
  # Args:
  #   cache_entry:: the number of the cache entry to load (0-based)
  #   node_id:: the node ID (not leaf ID) of the node to be loaded
  #   node_hash:: the node's hash
  #   old_parent_entry:: the cache entry holding the parent of the node held by
  #                      cache_entry before the load operation
  #
  # Raises:
  #   ArgumentError:: entry or old_parent_entry point to invalid cache entries
  #   ArgumentError:: node_id is an invalid hash tree node number
  #   RuntimeError:: entry is validated, and old_parent_entry does not
  #                  store the parent node of entry's node
  #   RuntimeError:: entry is validated, and its node has at least one child
  #                  stored in a validated cache entry
  #
  # A node's entry can only be overwritten if none of the node's children is
  # cached. When loading a new node in an entry, the old node's parent is
  # updated to reflect that its child is missing. The entry's verified flag is
  # cleared after it is a assigned a new value.
  def load(cache_entry, node_id, node_hash, old_parent_entry)
    
  end
  
  # Verifies the hash values of cached nodes based on their parent.
  #
  # Args:
  #   parent_entry:: the cache entry holding the parent node (0-based)
  #   left_child_entry:: the cache entry holding the left child (0-based)
  #   right_child_entry:: the cache entry holding the right child (0-based)
  #
  # Raises:
  #   ArgumentError:: parent_entry, left_child_entry, or right_child_entry point
  #                   to invalid entries in the cache
  #   RuntimeError:: the node in the parent entry is not verified
  #   RuntimeError:: the nodes stored in left_child and right_child aren't
  #                  the children of the node in parent
  #   RuntimeError:: a child is not verified, but the parent's corresponding
  #                  flag shows there is another verified entry for that child
  #                  in the cache
  #   RuntimeError:: the parent's hash does not match the children's hashes
  #
  # If the method succeeds, the verified flags will be set for both children.
  # The method correctly handles situations where a child was already verified.
  def verify(parent_entry, left_child_entry, right_child_entry)
    
  end

  # Certifies a leaf's contents.
  #
  # Args:
  #   session_id:: the session key cache entry for this client's session key
  #   nonce:: short random string that prevents replay attacks
  #   cache_entry:: the cache line holding the block's hash (0-based)
  #
  # Returns HMAC(session key, nonce || node number || block hash)
  def certify(session_id, nonce, cache_entry)
    
  end

  # Updates a leaf's contents.
  #
  # Args:
  #   session_id:: the session key cache entry for this client's session key
  #   update_path:: sequence of cache entries to be updated / checked during the
  #                 update process; even positions are the cache line numbers of
  #                 the nodes on the path between the leaf and the tree root,
  #                 and odd positions are the cache line numbers of the siblings
  #                 of the nodes in the corresponding even posittions
  #   node_hash:: the hash of the block's new contents
  #
  # Returns an array of updated node hashes for all the nodes on the path
  # between the leaf and the tree root.
  def update(session_id, update_path, node_hash)
    # TODO(pwnall): some sort of signature+nonce to authorize the write
  end
end  # module SpStore::PChip::NodeCache

end  # namespace SpStore::PChip

end  # namespace SpStore
