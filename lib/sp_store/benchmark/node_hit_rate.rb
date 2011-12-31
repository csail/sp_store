# :nodoc: namespace
module SpStore 
# :nodoc: namespace
module Benchmark
  
# redefine methods to calculate hit rate for node cache
module NodeCacheHitRate
    
  def self.calculate_hit_rate(detailed_info)

    SpStore::Server::HashTreeController.class_eval do
       alias_method :initialize_ori, :initialize
       def initialize(node_cache, hash_tree)
         reset_hit_info
         initialize_ori(node_cache, hash_tree)
       end

       def reset_hit_info
         @total_node_needed     = 0
         @total_node_to_load    = 0
       end
       attr_reader :total_node_needed, :total_node_to_load

       define_method :sign_read_block do |block_id, session_cache_entry, nonce|
         increment_access_time
         start_node_id = leaf_node_id block_id
         if node_cache_entry start_node_id # node_cache hit
            update_node_access_time start_node_id
            @total_node_needed  += 1
            puts "0 1" if detailed_info
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

       define_method :node_load_path_for_read do |node_id|
         node_ids            = []
         node_needed         = 1
         total_node_needed   = 1
         while node_id > 0
           if node_cache_entry node_id
             node_needed = node_id
             break
           end
           node_ids << node_id
           total_node_needed  += 2           
           if node_cache_entry sibling(node_id)
             node_needed = sibling(node_id)
             break
           end 
           node_ids << sibling(node_id) 
           node_id = parent node_id
         end
         update_node_access_time node_needed
         puts "#{node_ids.size} #{total_node_needed}" if detailed_info
         @total_node_to_load   += node_ids.size
         @total_node_needed    += total_node_needed
         return node_ids.reverse, ( node_ids << node_needed )
       end

       define_method :node_load_path_for_write do |node_id|
         nodes_needed  = []
         nodes_to_load = []
         visit_path_to_root node_id do |path_node_id|
            sibling_node   = sibling(path_node_id)
            nodes_needed  << path_node_id
            nodes_needed  << sibling_node unless path_node_id == root_node_id
            nodes_to_load << path_node_id unless node_cache_entry(path_node_id)
            nodes_to_load << sibling_node unless (path_node_id == root_node_id || node_cache_entry(sibling_node) )
         end
         puts "#{nodes_to_load.size} #{nodes_needed.size}" if detailed_info
         @total_node_needed   += nodes_needed.size
         @total_node_to_load  += nodes_to_load.size
         return nodes_to_load.reverse, nodes_needed.to_set
       end
         
    end
    
  end

end # namespace SpStore::Benchmark::NodeCacheHitRate

end # namespace SpStore::Benchmark

end # namespace SpStore