require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::PChip::SoftNodeCache do
  let(:session_key) { SpStore::Crypto.hmac_key }
  let(:session_id) { 42 }
  let(:session_cache) do
    session_cache = mock('session cache')
    session_cache.stub(:session_key).and_return session_key
    session_cache
  end
  let(:cache) { SpStore::PChip::SoftNodeCache.new 64, 1024, session_cache }
  let(:default_leaf) { SpStore::Crypto.crypto_hash '0' }
  let(:tree) { SpStore::Mocks::SoftHashTree.new 1024, default_leaf }

  before do
    @session_key = session_key
    @session_id = session_id
    @cache = cache
    @tree = tree
    cache.set_root_hash tree.node_hash(1)
  end

  it_should_behave_like 'a node cache'
end
