# :nodoc: namespace
module SpStore::Mocks
  
# Memory-backed block store implementation.
# Use file as disk
class FileStore
  # Creates a new block store with zeroed out blocks.
  #
  # Args:
  #   block_size:: the application-desired block size, in bytes
  #   block_count:: number of blocks
  def self.empty_store( block_size, block_count, disk_directory )

    raise ArgumentError, "Non-positive number of blocks: #{block_count}." if block_count <= 0
    raise ArgumentError, "Invalid disk directory: #{disk_directory}" unless Dir.exist? disk_directory
    
    disk_path = File.join( disk_directory, "mock_disk_store" )

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
    Dir.mkdir(disk_path, 0777) unless Dir.exist? disk_path
    
    #initialize disk data
    empty_block      = "\0" * block_size
    File.open(disk_data_file(disk_path), 'wb') do |file|
      (0...block_count).each { file.write empty_block }
    end
    
    #initialize disk hash
    empty_block_hash = SpStore::Crypto.crypto_hash empty_block
    File.open(disk_hash_file(disk_path), 'wb') do |file|
      (0...block_count).each { file.write empty_block_hash }
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
  def disk_hash
    node_hashes = Array.new(@blocks)
    File.open(disk_hash_file(@disk_path), 'rb') do |file|
      (0...@blocks).each do |idx|
        node_hashes[idx] = file.read(hash_byte_size)
      end
    end
    node_hashes
  end
  
  # Save the updated disk hash
  def save_disk_hash(hashes)
    raise ArgumentError, "Number of blocks does not match" unless @blocks == hashes.length
    File.open(disk_hash_file(@disk_path), 'wb') do |file|
      (0...@blocks).each do |block_id|
         file.write hashes[block_id]
      end
    end
  end
  
  module ClassMethods
    # Path to disk data file
    def disk_data_file(disk_path)
      File.join disk_path, 'disk_data'
    end
    # Path to disk hash file
    def disk_hash_file(disk_path)
      File.join disk_path, 'disk_hash'
    end    
    # Path to store attribute file
    def store_attribute_file
      File.join storage_path, 'mock_store_attributes'
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
  
end  # class SpStore::Mocks::FileStore
  
end  # namespace SpStore::Mocks
