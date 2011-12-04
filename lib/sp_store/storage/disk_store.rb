# :nodoc: namespace
module SpStore::Storage
  
# Memory-backed block store implementation.
class DiskStore
  # Creates a new block store with zeroed out blocks.
  #
  # Args:
  #   block_size:: the application-desired block size, in bytes, should be multiple of 64
  #   block_count:: number of blocks
  def self.empty_store( block_size, block_count, disk_directory )

    raise ArgumentError, "The block size (#{block_size}) should be multiple of 64." unless block_size%64 == 0
    raise ArgumentError, "Non-positive number of blocks: #{block_count}." if block_count <= 0
    raise ArgumentError, "Invalid disk directory: #{disk_directory}" unless Dir.exist? disk_directory
    
    disk_path = File.join( disk_directory, "sp_store_disk" )

    store_attributes = { :block_size  => block_size, 
                         :block_count => block_count,
                         :disk_path   => disk_path }
    
    #save store_attributes
    File.open(store_attribute_file, 'wb') do |file|
      store_attributes.each_pair do |key, value|
        file.write "#{key} #{value}\n"
      end
    end
    
    #initialize disk
    Dir.mkdir(disk_path, 0744) unless Dir.exist? disk_path
    
    #initialize disk data
    empty_block      = "\0" * block_size
    File.open(disk_data_file(disk_path), 'wb') do |file|
      (0...block_count).each { file.write empty_block }
    end
    
    #initialize disk hash_tree
    empty_block_hash = SpStore::Crypto.crypto_hash empty_block
    tree_size        = SpStore::Merkle::HashTreeHelper.full_tree_node_count block_count
    hash_tree        = SpStore::Mocks::SoftHashTree.new block_count, empty_block_hash
    File.open(disk_tree_file(disk_path), 'wb') do |file|
      file.seek(empty_block_hash.size, IO::SEEK_SET)
      (1..tree_size).each do |node|
         file.write hash_tree.node_hash(node)
      end
    end
    
    #initialize the file storage
    self.new store_attributes
  end

  def self.load_store
    #load store_attributes
    store_attributes = Hash.new
    File.open(store_attribute_file, 'rb') do |file|
      file.each do |line|
         key, value = line.split(' ')
         store_attributes[key.to_sym] = value
      end
    end
    unless store_attributes[:disk_path] && Dir.exist?(store_attributes[:disk_path])
      raise RuntimeError, 'Cannot load store: No existing store' 
    end
    store_attributes[:block_size]  = store_attributes[:block_size].to_i
    store_attributes[:block_count] = store_attributes[:block_count].to_i
    
    #initialize the file storage
    self.new store_attributes
  end

  require 'fileutils'

  def self.delete_store
    store_attributes = Hash.new
    File.open(store_attribute_file, 'rb') do |file|
      file.each do |line|
         key, value = line.split(' ')
         store_attributes[key.to_sym] = value
      end
    end
    File.delete store_attribute_file
    if store_attributes[:disk_path]
      store_path = store_attributes[:disk_path]
      FileUtils.rm_rf store_path if Dir.exist? store_path
    end
  end

  # De-serializes a block store model from the hash produced by Attributes.
  def initialize(attributes)
    @block_size = attributes[:block_size]
    @blocks     = attributes[:block_count]
    @disk_path  = attributes[:disk_path]
  end

  attr_reader :blocks  
  attr_reader :block_size

  # :nodoc
  def read_block_unchecked(block_id)
    File.open( disk_data_file(@disk_path), 'rb' ) do |file|
      file.seek(block_id*@block_size, IO::SEEK_SET)
      file.read(@block_size)
    end  
  end
  private :read_block_unchecked
  
  # :nodoc
  def write_block_unchecked(block_id, data)
    File.open( disk_data_file(@disk_path), 'rb+' ) do |file|
      file.seek(block_id*@block_size, IO::SEEK_SET)
      file.write data
    end
  end
  private :write_block_unchecked
  
  # Return the byte size of each data hash
  def hash_byte_size
    return 20
  end
  
  # Return the hash values of previous stored data
  def hash_tree
    tree_size = SpStore::Merkle::HashTreeHelper.full_tree_node_count @blocks
    node_hashes = Array.new(tree_size+1)
    File.open(disk_tree_file(@disk_path), 'rb') do |file|
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
    File.open(disk_tree_file(@disk_path), 'wb') do |file|
      file.seek( hash_byte_size, IO::SEEK_SET)
      (1..tree_size).each do |node|
         file.write node_hashes[node]
      end
    end
  end
  
  module ClassMethods
    # Path to disk data file
    def disk_data_file(disk_path)
      File.join disk_path, 'disk_data'
    end
    
    # Path to disk tree file
    def disk_tree_file(disk_path)
      File.join disk_path, 'disk_tree'
    end

    # Path to store attribute file
    def store_attribute_file
      File.join storage_path, 'store_attributes'
    end  
    def storage_path
      File.expand_path File.dirname(__FILE__)
    end    
  end
  
  include SpStore::Storage::StoreCallChecker
  include ClassMethods
  class <<self
    include ClassMethods
  end
  
end  # class SpStore::Storage::DiskStore
  
end  # namespace SpStore::Storage
