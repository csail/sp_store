require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Server::HashTreeController do
  
  let(:session_key)   { SpStore::Crypto.hmac_key }
  let(:session_entry) { 42 }
  let(:session_cache) do
    session_cache = mock('session cache')
    session_cache.stub(:session_key).and_return session_key
    session_cache
  end
  let(:nonce)             { SpStore::Crypto.nonce }
  let(:leaf_count)        { 1024 }
  let(:cache_size)        { 64 }
  let(:node_cache)        { SpStore::PChip::SoftNodeCache.new cache_size, leaf_count, session_cache }
  let(:default_leaf)      { SpStore::Crypto.crypto_hash '0' }
  let(:soft_tree)         { SpStore::Mocks::SoftHashTree.new leaf_count, default_leaf }

  before do
    node_cache.set_root_hash soft_tree.root_hash
    @controller  = SpStore::Server::HashTreeController.new node_cache, soft_tree.instance_variable_get(:@nodes).dup
    @cache_infos = @controller.instance_variable_get(:@cache_infos)
    @node_hashes = @controller.instance_variable_get(:@node_hashes)
  end

  describe 'after initialization' do
    it 'should cache the root node as the first entry' do
      @controller.node_cache_entry(1).should == 0
      lambda {
        node_cache.certify session_entry, nonce, 0
      }.should_not raise_error         
    end
  end

  let(:leaf_id)   { 0 }
  let(:node_id)   { leaf_node_id leaf_id }

  describe 'sign_read_block' do
    before do
      @hmac = @controller.sign_read_block( leaf_id, session_entry, nonce)      
    end
    it 'should produce a correct hmac for this read operation' do
      @hmac.should == SpStore::Crypto.hmac_for_block_hash(node_id, @node_hashes[node_id], nonce, session_key)
    end
    describe 'after read' do
      it 'the corresponding leaf node should be cached and verified' do
        cache_entry = @cache_infos[node_id].cache_entry
        lambda {
          node_cache.certify session_entry, nonce, cache_entry
        }.should_not raise_error      
      end      
    end
    describe 'when the node cache is full' do
      before do
        (1..50).each do |block_id|
           @controller.sign_read_block( block_id, session_entry, nonce)
        end
      end
      it 'should function correctly' do        
         @controller.sign_read_block( 110, session_entry, nonce).should == 
           SpStore::Crypto.hmac_for_block_hash(leaf_node_id(110), @node_hashes[leaf_node_id(110)], nonce, session_key)        
      end
    end
  end


  let(:new_leaf_hash) { SpStore::Crypto.crypto_hash 'new' }
  
  describe 'sign_write_block' do
    before do
      @hmac = @controller.sign_write_block( leaf_id, new_leaf_hash, session_entry, nonce)
      soft_tree[leaf_id] = new_leaf_hash    
    end
    it 'should produce a correct hmac for this write operation' do
      @hmac.should == SpStore::Crypto.hmac_for_block_hash(node_id, new_leaf_hash, nonce, session_key)
    end
    describe 'after write' do
      it 'nodes on the update path should be cached and verified' do
        node_update_path = soft_tree.node_update_path node_id
        node_update_path.each do |node|
          cache_entry = @cache_infos[node].cache_entry
          lambda {
            node_cache.certify session_entry, nonce, cache_entry
          }.should_not raise_error
        end
      end
      it 'the root hash should be changed correctly' do
        node_cache.instance_variable_get(:@node_hashes)[0].should == soft_tree.root_hash
      end
      it 'the leaf hash should be updated' do
        cache_entry = @cache_infos[node_id].cache_entry
        node_cache.instance_variable_get(:@node_hashes)[cache_entry].should == new_leaf_hash
      end
    end
    describe 'when the node cache is full' do
      before do
        (1..60).each do |block_id|
           @controller.sign_write_block( block_id, new_leaf_hash, session_entry, nonce)
           soft_tree[block_id] = new_leaf_hash
        end
      end
      it 'should function correctly' do
         leaf_id_2 = 178
         soft_tree[leaf_id_2] = new_leaf_hash 
         @controller.sign_write_block( leaf_id_2, new_leaf_hash, session_entry, nonce ).should == 
           SpStore::Crypto.hmac_for_block_hash(leaf_node_id(leaf_id_2), new_leaf_hash, nonce, session_key)
         node_cache.instance_variable_get(:@node_hashes)[0].should == soft_tree.root_hash
      end
    end
  end

 def leaf_node_id(leaf_id)
   @controller.capacity + leaf_id
 end

end
