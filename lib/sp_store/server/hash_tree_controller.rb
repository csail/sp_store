require 'set'
# :nodoc: namespace
module SpStore
  
# :nodoc: namespace
module Server

#  HashTreeController holds the node hash tree and controls 
#  the tree operation as well as caching policy of P chip's node cache
class HashTreeController
  # @cache is P chip's node cache
  # @node_hashes stores the whole hash tree
  # @cache_info stores the cache related information for each node, 
  # ex: cache_entry_id, access_time (for LRU)
  # @cache_leaves keeps track of the cached nodes that can be replaced
  def initialize(node_cache, hash_tree)
    @cache                 = node_cache
    @node_hashes           = hash_tree
    @cache_infos           = Array.new(hash_tree.length) { CacheInfo.new }
    @cache_leaves          = Set.new
    @num_of_used_entries   = 0
    @access_time           = 1
    cache_root_node
  end

  def cache_root_node
    @cache_infos[root_node_id].cache_entry = @num_of_used_entries
    update_node_access_time root_node_id
    @num_of_used_entries += 1 
  end
    
  def capacity
    @cache.leaf_count
  end

  def node_hash_unchecked(node_id)
    @node_hashes[node_id]
  end
  
  def node_cache_entry(node_id)
    @cache_infos[node_id].cache_entry
  end
  
  def increment_access_time
    @access_time += 1
  end
  
  def update_node_access_time(node_id)
    @cache_infos[node_id].access_time = @access_time
  end
  
  def sign_read_block(block_id, session_cache_entry, nonce)
    increment_access_time
    start_node_id = leaf_node_id block_id
    if node_cache_entry start_node_id # node_cache hit
       update_node_access_time start_node_id
    else # node_cache miss
       nodes_to_load, nodes_needed = node_load_path_for_read(start_node_id)
       nodes_needed_set            = nodes_needed.to_set
       # load and verify un-cached nodes
       verify_point = siblings?(nodes_to_load[0], nodes_needed.last) ? 0 : 1;
       nodes_to_load.each_with_index do |node, index|
         old_parent_entry = allocate_cache_entry(node, nodes_needed_set)
         load_node node, old_parent_entry
         next unless index % 2 == verify_point
         if index == 0
           verify_nodes node, nodes_needed.last
         else
           verify_nodes node, nodes_to_load[index-1]
         end
       end    
    end  
    @cache.certify session_cache_entry, nonce, node_cache_entry(start_node_id) 
  end
  
  def sign_write_block(block_id, data_hash, session_cache_entry, nonce)
    increment_access_time
    start_node_id = leaf_node_id block_id
    nodes_to_load, nodes_needed_set = node_load_path_for_write(start_node_id)
    nodes_to_load.each do |node|
      old_parent_entry = allocate_cache_entry(node, nodes_needed_set)
      load_node node, old_parent_entry
      next unless node_cache_entry(sibling(node))
      verify_nodes node, sibling(node)
    end
    update_path_entries = []
    @node_hashes[start_node_id] = data_hash
    visit_path_to_root start_node_id do |node|
      @node_hashes[node]  = correct_node_hash(node) unless leaf_node?(node)
      update_path_entries << node_cache_entry(node)
      update_path_entries << node_cache_entry(sibling(node)) unless node == root_node_id
    end
    @cache.update  update_path_entries, data_hash   
    @cache.certify session_cache_entry, nonce, node_cache_entry(start_node_id)
  end
  
  # for read operation
  # return the nodes that should be loaded into cache
  # also return nodes that should not be replaced
  def node_load_path_for_read(node_id)
    node_ids    = []
    node_needed = 1
    while node_id > 0
      if node_cache_entry node_id
        node_needed = node_id
        break
      end
      node_ids << node_id
      if node_cache_entry sibling(node_id)
        node_needed = sibling(node_id)
        break
      end 
      node_ids << sibling(node_id) 
      node_id = parent node_id
    end
    update_node_access_time node_needed
    return node_ids.reverse, ( node_ids << node_needed )
  end

  # for write/update operation
  # return the nodes that should be loaded into cache
  # also return nodes that should not be replaced
  def node_load_path_for_write(node_id)
    nodes_needed  = []
    nodes_to_load = []
    visit_path_to_root node_id do |path_node_id|
      sibling_node   = sibling(path_node_id)
      nodes_needed  << path_node_id
      nodes_needed  << sibling_node unless path_node_id == root_node_id
      nodes_to_load << path_node_id unless node_cache_entry(path_node_id)
      nodes_to_load << sibling_node unless (path_node_id == root_node_id || node_cache_entry(sibling_node) )
    end
    return nodes_to_load.reverse, nodes_needed.to_set
  end
  
  
  # allocate cache_entry to target node
  # should not use the cache entry that caches the node within the {needed_nodes} set
  def allocate_cache_entry( target_node, needed_nodes )
    if @num_of_used_entries < @cache.capacity  #use unused cache entries first
       @cache_infos[target_node].cache_entry = @num_of_used_entries
       @num_of_used_entries += 1
       @cache_leaves.add target_node
       @cache_leaves.delete parent(target_node)
       old_parent_entry = 0
    else # cache is full
       victim = choose_victim (@cache_leaves-needed_nodes)
       replace_cache victim, target_node
       old_parent_entry = node_cache_entry parent(victim)
    end
    update_node_access_time target_node
    old_parent_entry
  end
  
  # implement LRU caching policy
  def choose_victim(candidates)
    min_value = @access_time + 1
    min_node  = 0
    candidates.each do |node|
      if @cache_infos[node].access_time < min_value
        min_value, min_node = @cache_infos[node].access_time, node
      end
    end
    min_node
  end
  
  def replace_cache( victim, target_node )
    @cache_infos[target_node].cache_entry = node_cache_entry victim
    @cache_infos[victim].cache_entry      = nil
    @cache_leaves.add target_node
    @cache_leaves.delete parent(target_node)
    @cache_leaves.delete victim
    @cache_leaves.add parent(victim) unless node_cache_entry sibling(victim)
  end
  
  def verify_nodes( node_1, node_2 )
    parent_entry = node_cache_entry parent(node_1)
    node_1_entry = node_cache_entry node_1
    node_2_entry = node_cache_entry node_2
    if node_1 < node_2
      @cache.verify parent_entry, node_1_entry, node_2_entry
    else
      @cache.verify parent_entry, node_2_entry, node_1_entry
    end
  end
  
  def load_node( node, old_parent_entry )
    @cache.load node_cache_entry(node), node, @node_hashes[node], old_parent_entry
  end
  
  include SpStore::Merkle::HashTreeHelper
  include SpStore::Merkle::HashTreeCallChecker  

  class CacheInfo
    def initialize()
      @cache_entry   = nil
      @access_time   = 0
    end
    attr_accessor :cache_entry, :access_time   
  end  # class SpStore::Server::HashTreeController::CacheInfo

end  # class SpStore::Server::HashTreeController
  
end  # namespace SpStore::Server

end  # namespace SpStore
