require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::FileStore do

  let(:sp_store_path)  { File.expand_path(File.dirname(__FILE__) + '../../../../') }
  let(:disk_directory) { File.dirname(sp_store_path) }
  let(:block_size)     { 1024 }
  let(:block_count)    { 1024 }
  let(:default_leaf)   { SpStore::Crypto.crypto_hash "\0" * block_size }

  describe 'create a 1024-block, 1024-block size store' do
    before do
      @store = SpStore::Mocks::FileStore.empty_store block_size, block_count, disk_directory
    end
    after do
      SpStore::Mocks::FileStore.delete_store
    end   
    it_should_behave_like 'a block store'
    
    describe 'disk_hash' do
      it 'should return a previously saved hash values' do
        @store.disk_hash.each do |hash_value|
          hash_value.should == default_leaf
        end
      end
    end
    
    describe 'save_disk_hash' do
      it 'should save the given hash values' do
        new_hashes = Array.new(block_count) {default_leaf.reverse}
        @store.save_disk_hash new_hashes
        @store.disk_hash.each do |hash_value|
          hash_value.should == default_leaf.reverse
        end
      end
    end
        
  end
  
  describe 'load_store' do
    before do
      SpStore::Mocks::FileStore.empty_store block_size, block_count, disk_directory
    end
    after(:all) do
      SpStore::Mocks::FileStore.delete_store
    end
    it 'should load an existing store' do
      lambda {
        @store = SpStore::Mocks::FileStore.load_store
      }.should_not raise_error
    end
    it 'should fail to load if the store is not existed' do
      SpStore::Mocks::FileStore.delete_store
      lambda {
        @store = SpStore::Mocks::FileStore.load_store
      }.should raise_error
    end
    describe 'after the store is loaded' do
      before do
        @store = SpStore::Mocks::FileStore.load_store
      end
      it_should_behave_like 'a block store'
    end
  end 
  
end
