# :nodoc: namespace
module SpStore::Mocks

# Store disk data corresponding hash values
module HashStorage

  # Path to disk tree file
  def disk_hash_file
    File.join @disk_path, 'disk_hashes'
  end
  
  # Return the byte size of each data hash
  def hash_byte_size
    return 20
  end
  
  # Return the hash values of previous stored data
  def hashes
    node_hashes = Array.new(@blocks)
    File.open(disk_hash_file, 'rb') do |file|
      (0...@blocks).each do |idx|
        node_hashes[idx] = file.read(hash_byte_size)
      end
    end
    node_hashes
  end
  
  # Save the updated disk hash
  def save_hashes(hashes)
    raise ArgumentError, "Number of blocks does not match" unless @blocks == hashes.length
    File.open(disk_hash_file, 'wb') do |file|
      (0...@blocks).each do |block_id|
         file.write hashes[block_id]
      end
    end
  end

# inject empty_store as the class method of classes that include HashStorage
def self.included(other) 
  class <<other
    # Calls empty_store_without_hash
    # Then initializes disk hash tree and stores into disk
    #
    def empty_store( block_size, block_count, disk_directory )
      store     = empty_store_without_hash( block_size, block_count, disk_directory )
      #initialize disk hash
      empty_block_hash = SpStore::Crypto.crypto_hash empty_block(block_size)
      File.open( File.join( disk_path(disk_directory), 'disk_hashes' ), 'wb') do |file|
        (0...block_count).each { file.write empty_block_hash }
      end   
      store
    end    
  end
end
  
end  # module SpStore::Mocks::HashStorage
  
end  # namespace SpStore::Mocks
