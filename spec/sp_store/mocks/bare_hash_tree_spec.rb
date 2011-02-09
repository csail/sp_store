require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::BareHashTree do
  before do
    @tree = SpStore::Mocks::BareHashTree.new 1024, SpStore::Crypto.crypto_hash("\0")
  end
    
  it_should_behave_like 'a hash tree'
end
