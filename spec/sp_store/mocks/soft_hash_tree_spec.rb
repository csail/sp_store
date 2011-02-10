require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::SoftHashTree do
  let (:leaf_content) { SpStore::Crypto.crypto_hash("\0") }
  before do
    @tree = SpStore::Mocks::SoftHashTree.new 1000, leaf_content
  end
    
  it_should_behave_like 'a hash tree'
  
  it 'should respect the given capacity' do
    @tree.capacity.should == 1024
  end
  
  it 'should initialize the leaves with the leaf content' do
    @tree[0].should == leaf_content
    @tree[500].should == leaf_content
    @tree[1023].should == leaf_content
  end
end
