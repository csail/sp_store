# :nodoc: namespace
module SpStore::Mocks
  
# Integrity-checking hash tree implemented completly in software.
class SoftHashTree
  # Creates a hash tree where all the leaves have the same value.
  #
  # Args:
  #   min_capacity:: the minimum number of leaf nodes in the tree
  #   leaf_content:: the initial content of the tree leaves
  def initialize(min_capacity, leaf_content)
    @capacity = full_tree_leaf_count min_capacity
    
    @nodes = Array.new full_tree_node_count(min_capacity) + 1
    0.upto(@capacity - 1) { |i| @nodes[leaf_node_id(i)] = leaf_content.dup }
    (@capacity - 1).downto(1) do |node_id|
      @nodes[node_id] = correct_node_hash node_id
    end
  end
  
  def capacity
    @capacity
  end

  def update_unchecked(leaf_id, new_value)
    start_node_id = leaf_node_id leaf_id
    @nodes[start_node_id] = new_value
    visit_path_to_root start_node_id do |node_id|
      @nodes[node_id] = correct_node_hash node_id unless leaf_node?(node_id)
    end
    self
  end

  def node_hash_unchecked(node_id)
    @nodes[node_id]
  end
  
  include SpStore::Merkle::HashTreeHelper
  include SpStore::Merkle::HashTreeCallChecker
end  # class SpStore::Mocks::SoftHashTree
  
end  # namespace SpStore::Mocks
