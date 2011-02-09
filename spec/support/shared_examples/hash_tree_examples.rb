shared_examples_for 'a leaf' do
  describe 'update' do
    before do
      @old_root_hash = root_hash
      @old_hash = leaf_hash
      @new_hash = leaf_hash.reverse
      @tree[leaf_id] = @new_hash
    end
    after do
      @tree[leaf_id] = @old_hash
    end
    it 'should change the root hash' do
      root_hash.should_not == @old_root_hash
    end
    
    it 'should change the updated leaf' do
      leaf_hash.should == @new_hash
    end
    
    describe 'and reverted update' do
      before { @tree[leaf_id] = @old_hash }
      after { @tree[leaf_id] = @new_hash }

      it 'should have the initial root hash' do
        root_hash.should == @old_root_hash
      end
    end
  end
  
  # Duplicates HashTreeHelper functionality.
  def leaf_hash
    @tree.node_hash(@tree.capacity + leaf_id)
  end
end

# NOTE: this spec covers the HashTree interface, so it doesn't use the methods
#       in HashTreeHelper.
shared_examples_for 'a hash tree' do
  describe 'capacity' do
    let(:capacity) { @tree.capacity }
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end
    
  describe 'root hash' do
    it 'should be non-nil' do
      root_hash.should_not be_nil      
    end
    
    it 'should match the children' do
      root_hash.should == SpStore::Crypto.hash_for_tree_node(1,
          @tree.node_hash(2), @tree.node_hash(3))
    end
  end
  
  describe 'first leaf' do
    let(:leaf_id) { 0 }
    it_should_behave_like 'a leaf'
  end

  describe 'last leaf' do
    let(:leaf_id) { @tree.capacity - 1 }
    it_should_behave_like 'a leaf'
  end
  
  
  describe 'a leaf in the middle' do
    let(:leaf_id) { @tree.capacity / 2 }
    it_should_behave_like 'a leaf'    
  end
    
  # Duplicates HashTreeHelper functionality.
  def root_hash
    @tree.node_hash(1)
  end
end
