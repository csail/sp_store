require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::SoftSChip do
  let(:p_key) { SpStore::Crypto.sk_key }
  let(:puf_syndrome) { SpStore::Crypto.crypto_hash p_key }
  let(:endorsement_key) { SpStore::Crypto.key_pair }
  let(:ca_keys) { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:endorsement_certificate) do
    dn = { 'CN' => 'Mock P Chip' }
    SpStore::Crypto.cert dn, 1, ca_keys, SpStore::Mocks::FactoryKeys.ca_cert,
                         endorsement_key[:public]
  end
  let(:default_leaf) { SpStore::Crypto.crypto_hash '0' }
  let(:hash_tree) { SpStore::Mocks::SoftHashTree.new 1024, default_leaf }
  let(:root_hash) { hash_tree.node_hash 1 }
  
  let(:s_chip) do
    SpStore::Mocks::SoftSChip.new p_key, endorsement_key,
        endorsement_certificate, puf_syndrome, root_hash
  end
  let(:p_chip) do
    SpStore::Mocks::SoftPChip.new p_key, ca_keys[:public], :cache_size => 64,
        :capacity => 1024, :session_cache_size => 64
  end
  
  before do
    @s_chip = s_chip
    @p_chip = p_chip
    @hash_tree = hash_tree
  end
  
  it_should_behave_like 'a p chip'
end
