require 'openssl'

# :nodoc: namespace
module SpStore 
# :nodoc: namespace
module Benchmark
  
# initialize store controllers for benchmarking
module StoreSetup
    
  def StoreSetup.sp_store_controller( block_size, block_count, node_cache_size, session_cache_size, load_store = false, mock_p_chip = true, soft_hash_engine = false )
    
    # keys & certificate initialization
    p_key             = SpStore::Crypto.sk_key
    puf_syndrome      = SpStore::Crypto.crypto_hash p_key
    endorsement_key   = SpStore::Crypto.key_pair
    ca_keys           = SpStore::Mocks::FactoryKeys.ca_keys
    dn                = { 'CN' => 'S-P Store P Chip' }
    endorsement_certificate = SpStore::Crypto.cert dn, 1, ca_keys, SpStore::Mocks::FactoryKeys.ca_cert, endorsement_key[:public]

    # storage initialization
    if load_store
      store           = SpStore::Storage::DiskStore.load_store
      check_load_store store, block_size, block_count      
    else
      store           = SpStore::Storage::DiskStore.empty_store block_size, block_count, disk_directory 
    end

    # mock s_chip initialization
    root_hash         = store.disk_hash_tree[1]
    s_chip            = SpStore::Mocks::SoftSChip.new p_key, endorsement_key, endorsement_certificate, puf_syndrome, root_hash

    if mock_p_chip 
       # mock p_chip initialization
       p_chip         = SpStore::Mocks::SoftPChip.new p_key, ca_keys[:public], :cache_size => node_cache_size, 
                                                      :capacity => block_count, :session_cache_size => session_cache_size
       class << p_chip
         def set_connection(connector)
         end
       end
    else
       # hardware p_chip interface initialization
       p_chip         = SpStore::PChip::HardPChip.new p_key, ca_keys[:public], :cache_size => node_cache_size, 
                                                      :capacity => block_count, :session_cache_size => session_cache_size,
                                                      :soft_hash_engine => soft_hash_engine
    end

    # ethernet controller initialization
    ethernet          = SpStore::Communication::EthernetController.new 'eth0', 0x88B5, '0x001122334455'
    
    # controller initialization
    controller        = SpStore::Server::Controller.new store, s_chip, p_chip, ethernet
    
    # for multiple benchmarking
    # add reset function to reset node cache and cache info stored in the hash_tree_controller
    SpStore::Server::HashTreeController.class_eval do
      def reset_cache
        @cache_infos           = Array.new(@node_hashes.length) { CacheInfo.new }
        @cache_leaves          = Set.new
        @num_of_used_entries   = 0
        @access_time           = 1
        cache_root_node
      end
    end
    SpStore::PChip::HardNodeCache.class_eval do
      def reset
        command = [11].pack('C')
        @connector.send command
        ack = @connector.receive[0,2]
        raise RuntimeError, "Node Cache Reset Failed" unless ack == [0,255].pack('CC')
      end
    end    
    SpStore::Server::Controller.class_eval do
      define_method :reset_node_cache do
        @p.node_cache.reset unless mock_p_chip
        root_hash = @hash_tree_controller.node_hashes[1]
        @p.node_cache.set_root_hash(root_hash)
        @hash_tree_controller.reset_cache
      end
    end
    controller
  end

  def StoreSetup.bare_controller( block_size, block_count, load_store = false )
    # storage initialization
    if load_store
      store           = SpStore::Mocks::DiskStore.load_store
      check_load_store store, block_size, block_count      
    else
      store           = SpStore::Mocks::DiskStore.empty_store block_size, block_count, disk_directory 
    end
    ca_dn = {'CN' => 'SP Store Dev CA', 'C' => 'US'}
    ca_keys = SpStore::Crypto.key_pair
    ca_cert = SpStore::Crypto.cert ca_dn, 365, ca_keys
    controller = SpStore::Mocks::BareController.new store, ca_keys, ca_cert
  end
  
  def StoreSetup.check_load_store( store, block_size, block_count )
    if block_size != store.block_size
       raise ArgumentError, "The block size (#{block_size}) does not match that of the existing store ( #{store.block_size} )." 
    end
    if block_count != store.blocks
       raise ArgumentError, "The number of blocks (#{block_count}) does not match that of the existing store ( #{store.blocks} )." 
    end
  end
  
  def StoreSetup.disk_directory
    File.expand_path('../../../../../', __FILE__)
  end

  def StoreSetup.generate_write_data_file(block_size, block_count)
    write_disk_path = File.join( disk_directory, "sp_store_write_data" )
    disk_data_file  = File.join write_disk_path, "write_data"
    #initialize disk   
    Dir.mkdir(write_disk_path, 0777) unless Dir.exist? write_disk_path
    #initialize disk data
    File.open(disk_data_file, 'wb') do |file|
      (0...block_count).each do
         file.write OpenSSL::Random.random_bytes(block_size)
      end
    end
  end

end # namespace SpStore::Benchmark::StoreSetup

end # namespace SpStore::Benchmark

end # namespace SpStore