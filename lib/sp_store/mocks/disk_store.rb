# :nodoc: namespace
module SpStore::Mocks
  
# Memory-backed block store implementation.
# Use file as disk
# Store data blocks and corresponding hash values
class DiskStore

  # De-serializes a block store model from the hash produced by Attributes.
  def initialize(attributes)
    @block_size = attributes[:block_size]
    @blocks     = attributes[:block_count]
    @disk_path  = attributes[:disk_path]
  end

  attr_reader :blocks  
  attr_reader :block_size

  def self.disk_path(disk_directory)
    File.join disk_directory, "mock_disk_store"
  end

  def self.empty_block(block_size)
    "\0" * block_size
  end

  # Path to store attribute file
  def self.store_attribute_file
    File.join File.expand_path( File.dirname(__FILE__) ), 'mock_store_attributes'
  end

  def self._check_block_size( block_size )
    raise ArgumentError, "The block size (#{block_size}) should be positive." unless block_size > 0  
  end
  
include SpStore::Storage::FileStorageHelper
include SpStore::Storage::StoreCallChecker
include SpStore::Mocks::HashStorage
  
end  # class SpStore::Mocks::DiskStore
  
end  # namespace SpStore::Mocks
