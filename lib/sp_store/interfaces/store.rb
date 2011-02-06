# :nodoc: namespace
module SpStore
  
# API implemented by a block store.
module Store
	# The size of a block in this store.
	def block_size
		
	end

  # The number of blocks available in this store.
  def blocks
    
  end

  # Reads a block from the store.
  #
  # Args:
  #   block_id:: the 0-based number of the block to be read
  #
  # Returns a string of block_size bytes
  def read_block(block_id)
    
  end

  # Writes a block to the store.
  #
  # Args:
  #   block_id:: the 0-based number of the block to be written
  #   data:: a string of block_size bytes to be stored in the block
  #
  # Returns the store.
  def write_block(block_id, data)
    
  end
end

end  # namespace SpStore
