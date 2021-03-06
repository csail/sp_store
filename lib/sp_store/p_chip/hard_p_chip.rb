# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Hardware P chip implementation (using hardware hash engine & hardware node cache)
# Keep using software session cache and boot logic 
class HardPChip
  # Instantiates a new implementation of the P chip.
  #
  # Args:
  #   p_key:: the P chip's symmetric key; was generated during the manufacturing process
  #   ca_public_key:: the public key of the S-P chip pair's manufacturer root CA; 
  #                   this is burned in the P chip's ROM
  #   options:: supports the following keys
  #             cache_size:: number of entries in the node cache
  #             capacity:: number of data blocks supported
  #             session_cache_size:: number of session keys supported by the
  #                                  simulated chip's session cache
  def initialize(p_key, ca_public_key, options)
    @session_cache_size = options[:session_cache_size]
    @node_cache_size = options[:cache_size]
    @node_count = options[:capacity]
    @soft_hash_engine = options[:soft_hash_engine]
    @boot_logic = SpStore::PChip::SoftBootLogic.new p_key, ca_public_key, self
    @session_cache = nil
    @node_cache = nil
    @hash_engine = nil
    @boot_logic.reset
  end
  
  attr_reader :boot_logic
  attr_reader :session_cache
  attr_reader :node_cache
  attr_reader :hash_engine
  
  # :nodoc: called by boot logic
  def reset
    @session_cache = SpStore::PChip::SoftSessionCache.new @session_cache_size
    @node_cache    = SpStore::PChip::HardNodeCache.new @node_cache_size,
                                                       @node_count, @session_cache
    @hash_engine   = @soft_hash_engine ? SpStore::PChip::SoftHashEngine.new : SpStore::PChip::HardHashEngine.new
  end
  
  # :nodoc: called by boot logic, arguments never leave the chip
  def booted(root_hash, endorsement_key)
    @node_cache.set_root_hash root_hash
    @session_cache.set_endorsement_key endorsement_key
  end
  
  # passes the connected connection to node_cache & hash_engine
  def set_connection(connector)
    @node_cache.set_connection connector
    @hash_engine.set_connection connector unless @soft_hash_engine
  end
  
end  # class SpStore::PChip::HardPChip
  
end  # namespace SpStore::PChip
  
end  # namespace SpStore
