# :nodoc: namespace
module SpStore::Storage

# Store disk data corresponding hash tree 
module HashTreeStorage

  # Path to disk tree file
  def disk_hash_file
    File.join @disk_path, 'disk_hash_tree'
  end
  
  # Return the byte size of each data hash
  def hash_byte_size
    return 20
  end
  
  # Return the hash values of previous stored data
  def disk_hash_tree
    tree_size = SpStore::Merkle::HashTreeHelper.full_tree_node_count @blocks
    node_hashes = Array.new(tree_size+1)
    File.open(disk_hash_file, 'rb') do |file|
      file.seek(hash_byte_size, IO::SEEK_SET)
      (1..tree_size).each do |idx|
        node_hashes[idx] = file.read(hash_byte_size)
      end
    end
    node_hashes
  end
  
  # Save the updated hash tree
  def save_hash_tree(node_hashes)
    tree_size = SpStore::Merkle::HashTreeHelper.full_tree_node_count @blocks
    raise ArgumentError, "Hash tree size doesn't match the size of the existed one" unless (tree_size+1) == node_hashes.length
    File.open(disk_hash_file, 'wb') do |file|
      file.seek( hash_byte_size, IO::SEEK_SET)
      (1..tree_size).each do |node|
         file.write node_hashes[node]
      end
    end
  end

# inject empty_store as the class method of classes that include HashTreeStorage
def self.included(other) 
  class <<other
    # Calls empty_store_without_hash
    # Then initializes disk hash tree and stores into disk
    #
    def empty_store( block_size, block_count, disk_directory )
      store     = empty_store_without_hash( block_size, block_count, disk_directory )
      #initialize disk hash tree
      empty_block_hash = SpStore::Crypto.crypto_hash empty_block(block_size)
      tree_size        = SpStore::Merkle::HashTreeHelper.full_tree_node_count block_count
      hash_tree        = SpStore::Mocks::SoftHashTree.new block_count, empty_block_hash
      File.open( File.join( disk_path(disk_directory), 'disk_hash_tree' ), 'wb') do |file|
        file.seek(empty_block_hash.size, IO::SEEK_SET)
        (1..tree_size).each do |node|
           file.write hash_tree.node_hash(node)
        end
      end
      store
    end    
  end
end 
  
end  # module SpStore::Storage::HashTreeStorage
  
end  # namespace SpStore::Storage
