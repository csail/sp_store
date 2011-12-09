# :nodoc: namespace
module SpStore::Merkle

# Helper module that supplies utility methods for dealing with hash trees.
#
# The module should be included in classes implementing the HashTree interface.
module HashTreeHelper
  # Includes leaves and internal nodes.
  def nodes
    @_nodes ||= full_tree_node_count capacity
  end
  
  # Reads the content of a leaf.
  #
  # Args:
  #   leaf_id:: the 0-based ID for the leaf to be read
  #
  # Returns the hash value stored in the leaf.
  def [](leaf_id)
    node_hash leaf_node_id(leaf_id)
  end
  # The alernate method name below is used if HashTreeCallChecker is included.
  alias_method :leaf_hash_unchecked, :[]
  
  # The hash stored in the root node, which is a summary for the entire tree.
  def root_hash
    self.node_hash root_node_id
  end
  
  # Node ID for a leaf.
  #
  # Args:
  #   leaf_id:: 0-based leaf number
  #
  # Returns a node ID corresponding to that leaf.
  def leaf_node_id(leaf_id)
    # NOTE: internal node count = number of leaves - 1, and the nodes are
    #       numbered from 1 to leaves - 1, so the node ID of the first leaf is
    #       equal to the tree's capacity (number of leaves)
    capacity + leaf_id
  end
end

# :nodoc: implementatin helpers
module HashTreeHelper
  # True if a node ID corresponds to a leaf node.
  #
  # Args:
  #   node_id:: a node ID
  def leaf_node?(node_id)
    capacity <= node_id
  end
  
  # The set of nodes needed to update or verify the value of a leaf.
  def leaf_update_path(leaf_id)
    node_update_path leaf_node_id(leaf_id)
  end
  
  # The content of an internal tree node, assuming its children are correct.
  def correct_node_hash(node_id)
    SpStore::Crypto.hash_for_tree_node node_id, node_hash(left_child(node_id)),
                                                node_hash(right_child(node_id))
  end
end  # module SpStore::Merkle::HashTreeHelper

# :nodoc: namespace
module HashTreeHelper

# Node ID arithmetic for hash trees, which are pretty much full binary trees.
#
# These methods are available both as class methods and as instance methods on
# classes that include HashTreeHelper.
module ClassMethods
  # Number of leaves in a hash tree with a set minimum capacity (leaf count).
  #
  # The method rounds up its argument to the nearest power of two.
  def full_tree_leaf_count(min_capacity)
    # NOTE: a tree has at least one internal node (the root), so we want at
    #       least two leaves
    count = 2
    count *= 2 while count < min_capacity
    count
  end

  # Total number of nodes in a hash tree with a set minimum capacity.
  #
  # This includes both internal nodes and leaves.
  def full_tree_node_count(min_capacity)
    full_tree_leaf_count(min_capacity) * 2 - 1
  end
  
  # Node ID for the root node in the tree.
  def root_node_id
    1
  end

  # The node number of a node's left child.
  def left_child(node_id)
    node_id << 1  # node_id * 2
  end
  
  # The node number of a node's right child.
  def right_child(node_id)
    (node_id << 1) | 1  # node_id * 2 + 1
  end

  # The node number of a node's sibling.
  #
  # The sibling of a node is the parent's other child.
  def sibling(node_id)
    node_id ^ 1
  end
  
  # The node number of a node's parent.
  def parent(node_id)
    node_id >> 1  # node_id / 2
  end
  
  # True if two node numbers represent nodes with the same parent.
  def siblings?(node_id, other_node_id)
    node_id ^ other_node_id == 1
  end
  
  # True if the node is the left child of its parent.
  def left_child?(node_id)
    (node_id & 1) == 0  # node_id % 2 == 0
  end
  
  # True if the node is the right child of its parent.
  def right_child?(node_id)
    (node_id & 1) == 1  # node_id % 2 == 1
  end

  # Yields the IDs of the nodes on the path from a leaf to the root.
  #
  # Args:
  #   leaf_id:: the leaf starting the path
  #
  # Returns self.
  def visit_path_to_root(node_id)
    while node_id > 0
      yield node_id
      node_id = parent node_id
    end
    self
  end
  
  # The set of nodes needed to update or verify the value of a leaf.
  #
  # Args:
  #   node_id:: the leaf's node ID (not leaf ID)
  def node_update_path(node_id)
    node_ids = []
    visit_path_to_root node_id do |path_node_id|
      node_ids << path_node_id
      node_ids << sibling(path_node_id) unless path_node_id == root_node_id
    end
    node_ids
  end
end  # module SpStore::Merkle::HashTreeHelper::ClassMethods

include ClassMethods
class <<self
  include ClassMethods
end
# :nodoc: injects ClassMethods in classes and modules that pull HashTreeHelper
def included(other)
  class <<other
    include ClassMethods
  end
end

end  # module SpStore::Merkle::HashTreeHelper

end  # module SpStore::Merkle
