# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Software (untrusted) implementation of the P chip's node cache.
class SoftNodeCache
  # Instantiates a software model of the P chip's node cache module.
  def initialize(capacity, leaf_count, soft_session_cache)
    @capacity = capacity
    @leaf_count = leaf_count
    @key_cache = soft_session_cache
  end
  
  attr_reader :capacity
  
  attr_reader :leaf_count
  
  def certify(session_id, nonce, cache_entry)
    hmac_key = @key_cache.session_key session_id
    unsafe_certify hmac_key, nonce, cache_entry
  end
  
  def update(session_id, update_path, data_hash)
    hmac_key = @key_cache.session_key session_id
    # TODO(pwnall): some sort of signature+nonce to authorize the write
    
    unsafe_update update_path, data_hash
  end

  def load(cache_entry, node_id, node_hash, old_parent_entry)
    check_entry cache_entry
    if node_id <= 1 || node_id >= 2 * @leaf_count
      raise ArgumentError, "Invalid node id #{node_id.inspect}"
    end
    if @verified[cache_entry]
      check_entry old_parent_entry
      if @left_child[cache_entry] or @right_child[cache_entry]
        raise RuntimeError, "The entry's node has at least one child cached"
      end
      
      old_node_id = @node_ids[cache_entry]
      if @node_ids[old_parent_entry] != Helpers.parent(old_node_id)
        raise RuntimeError, 'Parent node not found at old_parent_entry'
      end
      if Helpers.left_child?(old_node_id)
        @left_child[old_parent_entry] = false
      else
        @right_child[old_parent_entry] = false
      end
    end
    @node_ids[cache_entry] = node_id
    @verified[cache_entry] = false
    @node_hashes[cache_entry] = node_hash
    @left_child[cache_entry] = @right_child[cache_entry] = false
  end

  def verify(parent, left_child, right_child)
    check_entry parent
    check_entry left_child
    check_entry right_child
  
    raise RuntimeError, 'Parent entry not verified' unless @verified[parent]
    unless @node_ids[left_child] == Helpers.left_child(@node_ids[parent])
      raise RuntimeError,
            "Incorrect left child entry #{left_child} for #{parent}"
    end
    unless @node_ids[right_child] == Helpers.right_child(@node_ids[parent])
      raise RuntimeError,
            "Incorrect right child entry #{right_child} for #{parent}"
    end
    unless @verified[left_child] == @left_child[parent]
      raise RuntimeError, 'Duplicate left child node'
    end
    unless @verified[right_child] == @right_child[parent]
      raise RuntimeError, 'Duplicate right child node'
    end
    
    parent_hash = SpStore::Crypto.hash_for_tree_node @node_ids[parent],
        @node_hashes[left_child], @node_hashes[right_child]
    unless @node_hashes[parent] == parent_hash
      raise RuntimeError, 'Verification failed'
    end
    @left_child[parent] = @right_child[parent] = true
    @verified[left_child] = @verified[right_child] = true
  end
  
  # :nodoc: called inside the P chip, argument's integrity is guaranteed.
  def set_root_hash(root_hash)
    @node_ids = Array.new capacity, nil
    @node_hashes = Array.new capacity, nil
    @verified = Array.new capacity, false    
    @left_child = Array.new capacity, false
    @right_child = Array.new capacity, false
  
    @node_ids[0] = 1
    @verified[0] = true
    @node_hashes[0] = root_hash
  end

  # :nodoc: software implementation of P-chip certify
  def unsafe_certify(hmac_key, nonce, cache_entry)
    check_entry cache_entry
    raise RuntimeError, 'Entry not verified' unless @verified[cache_entry]
    
    Crypto.hmac_for_block_hash @node_ids[cache_entry],
                               @node_hashes[cache_entry], nonce, hmac_key
  end
  private :unsafe_certify
  
  # :nodoc: actual implementation of P-chip update
  def unsafe_update(update_path, data_hash)
    update_path.each { |path_entry| check_entry path_entry }    
    check_update_path update_path
    
    @node_hashes[update_path.first] = data_hash
    visit_update_path update_path do |hot_entry, cold_entry, parent_entry|
      hot_node = @node_ids[hot_entry]
      cold_node = @node_ids[cold_entry]
      parent_node = @node_ids[parent_entry]
      @node_hashes[parent_entry] = if Helpers.left_child?(hot_node)
        SpStore::Crypto.hash_for_tree_node parent_node,
            @node_hashes[hot_entry], @node_hashes[cold_entry]
      else
        SpStore::Crypto.hash_for_tree_node parent_node,
            @node_hashes[cold_entry], @node_hashes[hot_entry]
      end
    end
  end
  private :unsafe_update
  
  # Checks that an entry number points to a valid entry in the cache.
  #
  # Args:
  #   entry:: the entry number to be verified
  #
  # Raises:
  #   RuntimeError:: if the entry number is invalid
  #
  # This method is called by public methods to validate their arguments. The
  # method can be made unnecessary in the FPGA implementation, if the cache
  # holds 2^n entries (only n bits will be read from the entry arguments).
  def check_entry(entry)
    if entry < 0 || entry >= @capacity
      raise ArgumentError, "Invalid cache entry #{entry.inspect}"
    end
  end
  private :check_entry
  
  # Verifies the validity of an update path.
  #
  # The return value is unspecified. 
  #
  # See update_leaf_value for a description of the path structure, verification
  # process, and exceptions that can be raised.
  def check_update_path(update_path)
    if @node_ids[update_path.first] < @leaf_count
      raise RuntimeError, "Update path does not start at a leaf"
    end
    if @node_ids[update_path.last] != 1
      raise RuntimeError, "Update path does not contain root node"
    end
    
    visit_update_path update_path do |hot_entry, cold_entry, parent_entry|
      unless Helpers.siblings?(@node_ids[hot_entry], @node_ids[cold_entry])
        raise RuntimeError,
              "Path contains non-siblings #{hot_entry} and #{cold_entry}"
      end
      unless Helpers.parent(@node_ids[hot_entry]) == @node_ids[parent_entry]
        raise RuntimeError,
              "Path entry #{parent_entry} is not parent for #{hot_entry}"
      end
      
      # NOTE: the checks below will not run for the root node; that's OK, the
      #       root node is always verified, as it never leaves the cache
      unless @verified[hot_entry]
        raise RuntimeError, "Unverified entry #{hot_entry}"
      end
      unless @verified[cold_entry]
        raise RuntimeError, "Unverified entry #{cold_entry}"
      end
    end
  end
  private :check_update_path

  # Yields every tree level in a path used to update a leaf's value.
  #
  # Args:
  #   update_path:: array of cache entries, as described in update_leaf_value
  #
  # Yields:
  #   hot_entry:: entry containing a node whose hash will be re-computed
  #   cold_entry:: entry containing the sibling of the node in hot_entry
  #   parent_entry:: entry containing the parent of the node in hot_entry
  #
  # The return value is not specified.
  def visit_update_path(update_path)
    (0...(update_path.length / 2)).map do |i|
      hot_entry = update_path[i * 2]  # Node to be updated.
      cold_entry = update_path[i * 2 + 1]  # Sibling of the node to be updated.
      parent_entry = update_path[i * 2 + 2]  # Parent of the node to be updated.
    
      yield hot_entry, cold_entry, parent_entry
    end
  end
  private :visit_update_path
  
  Helpers = SpStore::Merkle::HashTreeHelper
end  # class SpStore::PChip::SoftNodeCache
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
