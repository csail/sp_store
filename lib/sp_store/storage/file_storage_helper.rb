# :nodoc: namespace
module SpStore::Storage
  
# Memory-backed block store implementation.
# Use file as disk to store data blocks
module FileStorageHelper

  # :nodoc
  def read_block(block_id)
    File.open( disk_data_file, 'rb' ) do |file|
      file.seek(block_id*@block_size, IO::SEEK_SET)
      file.read(@block_size)
    end  
  end
  alias_method :read_block_unchecked, :read_block
  
  # :nodoc
  def write_block(block_id, data)
    File.open( disk_data_file, 'rb+' ) do |file|
      file.seek(block_id*@block_size, IO::SEEK_SET)
      file.write data
    end
  end
  alias_method :write_block_unchecked, :write_block
 
  # Path to disk data file
  def disk_data_file
    File.join @disk_path, 'disk_data'
  end


module ClassMethods

  # Creates a new block store with zeroed out blocks
  #
  # Args:
  #   block_size:: the application-desired block size, in bytes, should be multiple of 64
  #   block_count:: number of blocks
  def empty_store( block_size, block_count, disk_directory )

    _check_block_size  block_size
    _check_block_count block_count
    _check_disk_directory disk_directory
        
    disk_path = disk_path disk_directory

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
    File.open( File.join(disk_path,'disk_data'), 'wb') do |file|
      (0...block_count).each { file.write empty_block(block_size) }
    end
   
    #initialize the file storage
    self.new store_attributes
  end
  alias_method :empty_store_without_hash, :empty_store

  def load_store
    #load store_attributes
    raise RuntimeError, 'Cannot load store: No existing store' unless File.exist? store_attribute_file
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
    
  def delete_store
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

  # Path to store attribute file
  def store_attribute_file
    File.join storage_path, 'store_attributes'
  end
  
  # :nodoc
  def _check_block_count(block_count)
    raise ArgumentError, "Non-positive number of blocks: #{block_count}." if block_count <= 0
  end
  private :_check_block_count
  
  # :nodoc
  def _check_disk_directory(disk_directory)
    raise ArgumentError, "Invalid disk directory: #{disk_directory}" unless Dir.exist? disk_directory
  end
  private :_check_disk_directory
 
end
  
# :nodoc: injects ClassMethods in classes that pull FileStorageHelper
def self.included(other)
  class <<other
    include ClassMethods
  end
end
  

end  # module SpStore::Storage::FileStorageHelper
  
end  # namespace SpStore::Storage
