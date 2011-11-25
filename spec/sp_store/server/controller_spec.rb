require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Server::Controller do
  let(:p_key)           { SpStore::Crypto.sk_key }
  let(:puf_syndrome)    { SpStore::Crypto.crypto_hash p_key }
  let(:endorsement_key) { SpStore::Crypto.key_pair }
  let(:ca_keys)         { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:endorsement_certificate) do
    dn = { 'CN' => 'Mock P Chip' }
    SpStore::Crypto.cert dn, 1, ca_keys, SpStore::Mocks::FactoryKeys.ca_cert, endorsement_key[:public]
  end 
  
  let(:block_size)         { 1024 }
  let(:block_count)        { 1024 }
  let(:node_cache_size)    {   64 }
  let(:session_cache_size) {   64 }
  
  let(:default_leaf)       { SpStore::Crypto.crypto_hash "\0" * block_size }
  let(:hash_tree)          { SpStore::Mocks::SoftHashTree.new block_count, default_leaf }
  let(:root_hash)          { hash_tree.node_hash 1 }
  
  let(:sp_store_path)      { File.expand_path(File.dirname(__FILE__) + '../../../../') }
  let(:disk_directory)     { File.dirname(sp_store_path) }  
  let(:store)              { SpStore::Storage::DiskStore.empty_store block_size, block_count, disk_directory } 
  
  let(:s_chip) do
    SpStore::Mocks::SoftSChip.new p_key, endorsement_key,
        endorsement_certificate, puf_syndrome, root_hash
  end
  let(:p_chip) do
    SpStore::Mocks::SoftPChip.new p_key, ca_keys[:public], :cache_size => node_cache_size,
        :capacity => block_count, :session_cache_size => session_cache_size
  end
  
  before do
    @controller = SpStore::Server::Controller.new store, s_chip, p_chip
  end   
  
  def node_id(block_id)
    block_id + block_count
  end

  it_should_behave_like 'a store controller'
  
end
