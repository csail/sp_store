# :nodoc: namespace
module SpStore::Merkle

# Helper module that verifies checks the parameters for all method calls.
module HashTreeCallChecker
  # Calls leaf_hash_unchecked if leaf_id is valid.
  #
  # Raises an IllegalArgumentException if leaf_id is invalid.
  def [](leaf_id)
    _check_leaf_id leaf_id
    leaf_hash_unchecked leaf_id, new_value
  end

  # Calls update_leaf_unchecked if leaf_id is valid.
  #
  # Raises an IllegalArgumentException if leaf_id is invalid.
  def []=(leaf_id, new_value)
    _check_leaf_id leaf_id
    update_unchecked leaf_id, new_value
  end

  # Calls node_hash_unchecked if node_id is valid.
  #
  # Raises an IllegalArgumentException if node_id is invalid.
  def node_hash(node_id)
    _check_node_id node_id
    node_hash_unchecked node_id
  end
  
  # :nodoc
  def _check_leaf_id(leaf_id)
    raise ArgumentError, "Negative leaf id #{leaf_id}" if leaf_id < 0
    if self.capacity <= leaf_id
      raise ArgumentError,
            "Leaf id #{leaf_id} exceeds tree capacity #{capacity}"
    end
  end
  private :_check_leaf_id
  
  # :nodoc
  def _check_node_id(node_id)
    # NOTE: nodes are numbered starting from 1, to make tree arithmetic work
    raise ArgumentError, "Non-positive node id #{node_id}" if node_id <= 0
    node_count = self.capacity * 2 - 1
    if node_count < node_id
      raise ArgumentError, "Node id #{node_id} exceeds node count #{node_count}"
    end
  end
  private :_check_node_id
end  # module SpStore::Merkle::HashTreeCallChecker

end  # namespace SpStore::Merkle
