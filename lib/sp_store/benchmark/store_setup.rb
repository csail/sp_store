# :nodoc: namespace
module SpStore 
# :nodoc: namespace
module Benchmark
  
# initialize store controllers for benchmarking
module StoreSetup
    
  def StoreSetup.sp_store_controller( block_size, block_count, node_cache_size, session_cache_size, load_store = false, mock_p_chip = true )
    
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
    root_hash         = store.hash_tree[1]
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
                                                      :capacity => block_count, :session_cache_size => session_cache_size
    end

    # ethernet controller initialization
    ethernet          = SpStore::Communication::EthernetController.new 'eth0', 0x88B5, '0x001122334455'
    
    # controller initialization
    controller        = SpStore::Server::Controller.new store, s_chip, p_chip, ethernet
      
  end

  def StoreSetup.bare_controller( block_size, block_count, load_store = false )
    # storage initialization
    if load_store
      store           = SpStore::Mocks::FileStore.load_store
      check_load_store store, block_size, block_count      
    else
      store           = SpStore::Mocks::FileStore.empty_store block_size, block_count, disk_directory 
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

end # namespace SpStore::Benchmark::StoreSetup

end # namespace SpStore::Benchmark

end # namespace SpStore