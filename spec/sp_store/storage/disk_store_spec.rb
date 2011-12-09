require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Storage::DiskStore do

  let(:sp_store_path)  { File.expand_path(File.dirname(__FILE__) + '../../../../') }
  let(:disk_directory) { File.dirname(sp_store_path) }

  let(:block_size)     { 1024 }
  let(:block_count)    { 1024 }
  let(:default_leaf)   { SpStore::Crypto.crypto_hash "\0" * block_size }
  let(:soft_tree)      { SpStore::Mocks::SoftHashTree.new block_count, default_leaf }
  

  describe 'create a 1024-block, 1024-block size store' do
    before do
      @store = SpStore::Storage::DiskStore.empty_store block_size, block_count, disk_directory
    end
    after do
      SpStore::Storage::DiskStore.delete_store
    end
    
    it_should_behave_like 'a block store'
    
    describe 'disk_hash_tree' do
      it 'should return a previously saved hash_tree' do
        @store.disk_hash_tree[1..-1].should == soft_tree.instance_variable_get(:@nodes)[1..-1]
      end
    end
    
    describe 'save_hash_tree' do
      it 'should save the given hash_tree' do
        soft_tree[5] = default_leaf.reverse
        @store.save_hash_tree soft_tree.instance_variable_get(:@nodes).dup
        @store.disk_hash_tree[1..-1].should == soft_tree.instance_variable_get(:@nodes)[1..-1]
      end
    end
  
  end
  
  describe 'load_store' do
    before do
      SpStore::Storage::DiskStore.empty_store block_size, block_count, disk_directory
    end
    after(:all) do
      SpStore::Storage::DiskStore.delete_store
    end
    it 'should load an existing store' do
      lambda {
        @store = SpStore::Storage::DiskStore.load_store
      }.should_not raise_error
    end
    it 'should fail to load if the store is not existed' do
      SpStore::Storage::DiskStore.delete_store
      lambda {
        @store = SpStore::Storage::DiskStore.load_store
      }.should raise_error
    end
    describe 'after the store is loaded' do
      before do
        @store = SpStore::Storage::DiskStore.load_store
      end
      it_should_behave_like 'a block store'
    end
  end 
  
end
