# The examples expect a tree associated with the cache.
shared_examples_for 'a node cache' do
  let(:capacity) { @cache.capacity }
  describe 'capacity' do
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end

  let(:leaf_count) { @cache.leaf_count }
  describe 'leaf_count' do
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end
  
  let(:nonce) { SpStore::Crypto.nonce }
  
  describe 'load' do
    before do
      @cache.load 1, 2, @tree.node_hash(2), -1
      @cache.load 2, 3, @tree.node_hash(3), -1
    end
    
    it 'should invalidate the entry' do
      @cache.load 1, leaf_count, @tree.node_hash(leaf_count), -1
      lambda {
        @cache.certify @session_id, nonce, 1
      }.should raise_error
    end
    it 'should generate entries which can be verified' do
      lambda {
        @cache.verify 0, 1, 2
      }.should_not raise_error
    end
    it 'should fail if given incorrect parents' do
      @cache.verify 0, 1, 2
      lambda {
        @cache.load 1, 4, @tree.node_hash(4), 2
      }.should raise_error
    end
    
    it 'should fail on negative entries' do
      lambda {
        @cache.load -1, 2, @tree.node_hash(2), -1
      }.should raise_error
    end

    it 'should fail on entries outside the table size' do
      lambda {
        @cache.load capacity + 1, 2, @tree.node_hash(2), -1
      }.should raise_error
    end

    it 'should unmark left child when given correct parent' do
      @cache.verify 0, 1, 2
      @cache.load 1, 4, @tree.node_hash(4), 0
      @cache.load 3, 2, @tree.node_hash(2), -1
      lambda {
        @cache.verify 0, 3, 2
      }.should_not raise_error
    end

    it 'should unmark right child when given correct parent' do
      @cache.verify 0, 1, 2
      @cache.load 2, 4, @tree.node_hash(4), 0
      @cache.load 3, 3, @tree.node_hash(3), -1
      lambda {
        @cache.verify 0, 1, 3
      }.should_not raise_error
    end
    
    it 'should unmark both children when given correct parents' do
      @cache.verify 0, 1, 2
      @cache.load 1, 4, @tree.node_hash(4), 0
      @cache.load 2, 5, @tree.node_hash(5), 0
      @cache.load 3, 2, @tree.node_hash(2), -1
      @cache.load 4, 3, @tree.node_hash(3), -1
      lambda {
        @cache.verify 0, 3, 4
      }.should_not raise_error
    end
  end
  
  describe 'verify' do
    before do
      @cache.load 1, 2, @tree.node_hash(2), -1
      @cache.load 2, 3, @tree.node_hash(3), -1
      @cache.verify 0, 1, 2
    end
    
    it 'should mark the entry as valid' do
      lambda {
        @cache.certify @session_id, nonce, 1
      }.should_not raise_error
    end
    
    it 'should disallow another verification of the left child' do
      @cache.load 3, 2, @tree.node_hash(2), -1
      lambda {
        @cache.verify 0, 3, 2
      }.should raise_error
    end
    
    it 'should disallow another verification of the right child' do
      @cache.load 3, 3, @tree.node_hash(3), -1
      lambda {
        @cache.verify 0, 1, 3
      }.should raise_error
    end
    
    it 'should fail if left / right children are mismatched' do
      @cache.load 1, 2, @tree.node_hash(2), 0
      @cache.load 2, 3, @tree.node_hash(3), 0
      lambda {
        @cache.verify 0, 2, 1
      }.should raise_error
    end
  end
  
  describe 'after leaf load' do
    let(:update_path) { @tree.leaf_update_path 0 }
    let(:cache_path) { update_path.reverse }
    before do
      cache_path.each_with_index do |node, index|
        next if index == 0
        @cache.load index, node, @tree.node_hash(node), -1
        next unless index % 2 == 0
        if cache_path[index - 1] < cache_path[index]
          @cache.verify index - 2, index - 1, index
        else
          @cache.verify index - 2, index, index - 1
        end
      end
    end
    describe 'certify' do
      it 'should produce a correct hmac' do
        @cache.certify(@session_id, nonce, cache_path.length - 1).
            should == SpStore::Crypto.hmac_for_block_hash(cache_path.last,
            @tree.node_hash(cache_path.last), nonce, @session_key)
      end
    end
  end
end
