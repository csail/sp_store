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
    
    it 'should be the same for the same values in leaves' do
      old_root_hash = root_hash
      @tree[0] = first_leaf.reverse
      @tree[0] = first_leaf.reverse
      root_hash.should == old_root_hash
    end
  end
  
  describe 'updating' do
    it 'should change the root hash' do
      old_root_hash = root_hash
      @tree[0] = first_leaf.reverse
      root_hash.should_not == old_root_hash
    end
    
    it 'should change the updated leaf' do
      new_leaf = first_leaf.reverse
      @tree[0] = new_leaf
      first_leaf.should == new_leaf
    end
  end

  # Duplicates HashTreeHelper functionality.
  def root_hash
    @tree.node_hash(1)
  end
  
  # Duplicates HashTreeHelper functionality.
  def first_leaf
    @tree.node_hash(@tree.capacity)
  end
end
