# :nodoc: namespace
module SpStore::Models
  
# Memory-backed block store implementation.
class RamStore
  # Creates a new block store model.
  #
  # Args:
  #   block_size:: the application-desired block size, in bytes
  #   block_count:: number of blocks; caller should make sure blocks fit in RAM
  def self.empty_store(block_size, block_count)
    empty_block = "\0" * block_size
    self.new :block_size => block_size, :block_count => block_count,
             :blocks => Array.new(block_count) { empty_block.dup }
  end
  
  # De-serializes a block store model from the hash produced by Attributes.
  def initialize(attributes)
    @block_size = attributes[:block_size]
    @blocks = attributes[:block_count]
    @block_data = attributes[:blocks].map(&:dup)
  end
  
  # Serializes this disk model to a Hash of primitives.
  def attributes
    {
      :block_size => @block_size, :block_count => @blocks,
      :blocks => @block_data.map(&:dup)
    }
  end

  attr_reader :blocks  
  attr_reader :block_size

  # :nodoc
  def read_block_without_checks(block_id)
    @block_data[block_id].dup
  end
  private :read_block_without_checks
  
  # :nodoc
  def write_block_without_checks(block, data)
    raise "Wrong data buffer size" if data.length != block_size
    @block_data[block_id] = data.dup
  end
  private :write_block_without_checks
end
  
end  # namespace SpStore::Models
