# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Interface with hardware implementation of P chip's node cache (on FPGA)
class HardNodeCache
  # Instantiates a P chip's node cache module 
  # serving as the interface with the real P chip's node cache on FPGA
  def initialize(capacity, leaf_count, soft_session_cache)
    @capacity     = capacity
    @leaf_count   = leaf_count
    @key_cache    = soft_session_cache
    @connector    = nil
    @byte_in_hmac = 20
  end
  
  attr_reader :capacity, :leaf_count

  def set_connection(connector)
    @connector = connector
  end

  # load root: op_code(8'h05) + node_hash ( 160 bits )
  def set_root_hash(root_hash)
    command = [[5].pack('C'), root_hash].join
    @connector.send command
  end

  require 'timeout'
  # return HMAC value: op_code(8'h06)+ cache_entry(16bits) 
  #                                  + section key(128bits)+ nonce(128bits)
  def certify(session_id, nonce, cache_entry)
    hmac_key = @key_cache.session_key session_id
    command  = [[6].pack('C'), [cache_entry].pack('n'), hmac_key, nonce].join
    @connector.send command
    #data     = nil
    #Timeout::timeout(5) { data = @connector.receive[1,@byte_in_hmac] }
    #data
    @connector.receive[1,@byte_in_hmac]
  end
  
  # update: op_code(8'h07) + command_length( 8 bits) 
  #                        + current_entry (24 bits) 
  #                        + neighbor_entry(16 bits)
  #                        + parent_entry  (16 bits) 
  #                        + hash(160 bits) 
  #                        + { neighbor_entry(16 bits) + parent_entry(16 bits) } x n
  # command_length: length of the command in 32-bit unit, op_code not included
  def update(update_path, data_hash)
    command = [[7].pack('C')]
    command_length = 7 + (update_path.length - 3)/2
    command<<[command_length].pack('C')
    command<<[update_path[0]].pack('N')[1, 3]
    command<<update_path[1..2].pack('nn')
    command<<data_hash
    command<<update_path[3..-1].pack('n*')
    @connector.send command.join
  end

  # load node: op_code(8'h00) + current entry ( 16 bits ) 
  #                           + parent entry  ( 16 bits )  
  #                           + node_id (24 bits) + node_hash (160 bits)
  def load(cache_entry, node_id, node_hash, old_parent_entry)
    command = [[0].pack('C'), [cache_entry, old_parent_entry].pack('nn'),
     [node_id].pack('N')[1, 3], node_hash].join
    @connector.send command
  end

  # verify 1 pair : op_code(8'h01) + right_child_entry ( 16 bits ) 
  #                                + left _child_entry ( 16 bits ) 
  #                                + parent entry ( 16 bits )
  def verify(parent, left_child, right_child)
    command = [1, right_child, left_child, parent].pack('Cnnn')
    @connector.send command
  end
  
end  # class SpStore::PChip::HardNodeCache
  
end  # namespace SpStore::PChip
  
end  # namespace SpStore
