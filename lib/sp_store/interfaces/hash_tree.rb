# :nodoc: namespace
module SpStore
  
# API implemented by a hash tree designed for integrity verification.
module HashTree
  # Number of leaves in the tree.
  def capacity
    
  end

  # Updates the contents of a leaf.
  #
  # Args:
  #   leaf_id:: the leaf whose value is updated
  #   new_value:: the leaf's new value
  #
  # Returns new_value.
  def []=(leaf_id, new_value)
    
  end

  # The content of a tree node.
  #
  # This method can read both leaves and internal nodes. HashTreeHelper provides
  # [], which has an easier API for dealing exclusively with leaves.
  #
  # Args:
  #   node_id:: the ID of the node to be read
  #
  # Returns the hash value stored in the node.
  def node_hash(node_id)
    
  end
end  # class SpStore::HashTree

end  # namespace SpStore
