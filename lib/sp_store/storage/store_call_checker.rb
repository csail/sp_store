# :nodoc: namespace
module SpStore::Storage

# Helper module that verifies checks the parameters for all method calls.
module StoreCallChecker
  # Calls read_block_unchecked if block_id is valid.
  #
  # Raises an IllegalArgumentException if block_id is invalid.
  def read_block(block_id)
    _check_block_id block_id
    read_block_unchecked block_id
  end

  # Writes a block to the store.
  #
  # Args:
  #   block_id:: the 0-based number of the block to be written
  #   data:: a string of block_size bytes to be stored in the block
  #
  # Returns the store.
  def write_block(block_id, data)
    _check_block_id block_id
    _check_block_data data
    write_block_unchecked block_id, data
  end
  
  # :nodoc
  def _check_block_id(block_id)
    raise ArgumentError, "Negative block #{block_id}" if block_id < 0
    if self.blocks <= block_id
      raise ArgumentError, "Block #{block_id} exceeds store size #{blocks}"
    end
  end
  private :_check_block_id
  
  # :nodoc
  def _check_block_data(data)
    # TODO(pwnall): check that the data encoding is ASCII or convert to ASCII
    if data.length != block_size
      raise ArgumentError,
          "Cannot write #{data.length} bytes, the  block size is #{block_size}"
    end
  end
  private :_check_block_data
end

end  # namespace SpStore::Storage
