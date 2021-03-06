require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Merkle::HashTreeHelper do
  let(:klass) { SpStore::Merkle::HashTreeHelper }
  
  describe 'full_tree_leaf_count' do
    it 'should have a special case for 1' do
      klass.full_tree_leaf_count(1).should == 2
    end
    
    it 'should return the argument for powers of 2' do
      klass.full_tree_leaf_count(2).should == 2
      klass.full_tree_leaf_count(4).should == 4
      klass.full_tree_leaf_count(1024).should == 1024
      klass.full_tree_leaf_count(65536).should == 65536
    end
    
    it 'should round up the argument for non-powers of 2' do
      klass.full_tree_leaf_count(3).should == 4
      klass.full_tree_leaf_count(5).should == 8
      klass.full_tree_leaf_count(7).should == 8
      klass.full_tree_leaf_count(9).should == 16
      klass.full_tree_leaf_count(1023).should == 1024
      klass.full_tree_leaf_count(1025).should == 2048
      klass.full_tree_leaf_count(65535).should == 65536
    end
  end
  
  describe 'full_tree_node_count' do
    it 'should have a special case for 1' do
      klass.full_tree_node_count(1).should == 3
    end
    
    it 'should return 2n-1 for powers of 2' do
      klass.full_tree_node_count(2).should == 3
      klass.full_tree_node_count(4).should == 7
      klass.full_tree_node_count(1024).should == 2047
      klass.full_tree_node_count(32768).should == 65535
    end
    
    it 'should round up the argument for non-powers of 2' do
      klass.full_tree_node_count(3).should == 7
      klass.full_tree_node_count(5).should == 15
      klass.full_tree_node_count(7).should == 15
      klass.full_tree_node_count(9).should == 31
      klass.full_tree_node_count(1023).should == 2047
      klass.full_tree_node_count(1025).should == 4095
      klass.full_tree_node_count(32767).should == 65535
    end    
  end
  
  describe 'parent' do
    it 'should work for left node' do
      klass.parent(2).should == 1
      klass.parent(4).should == 2
      klass.parent(100).should == 50
    end
    
    it 'should work for right node' do
      klass.parent(3).should == 1
      klass.parent(5).should == 2
      klass.parent(101).should == 50
    end
  end

  describe 'left_child' do
    it 'should work for root' do
      klass.left_child(1).should == 2
    end
    
    it 'should work for inner nodes' do
      klass.left_child(2).should == 4
      klass.left_child(100).should == 200
    end
  end

  describe 'right_child' do
    it 'should work for root' do
      klass.right_child(1).should == 3
    end
    
    it 'should work for inner nodes' do
      klass.right_child(2).should == 5
      klass.right_child(100).should == 201
    end
  end
  
  describe 'sibling' do
    it 'should work for left nodes' do
      klass.sibling(2).should == 3
      klass.sibling(4).should == 5
      klass.sibling(100).should == 101
    end
    
    it 'should work for right nodes' do
      klass.sibling(3).should == 2
      klass.sibling(5).should == 4
      klass.sibling(101).should == 100
    end
  end

  describe 'siblings?' do
    it 'should be false for identical nodes' do
      klass.siblings?(1, 1).should be_false
      klass.siblings?(2, 2).should be_false
      klass.siblings?(3, 3).should be_false
      klass.siblings?(100, 100).should be_false
    end
    
    it 'should be false for parent-child nodes' do
      klass.siblings?(1, 2).should be_false
      klass.siblings?(1, 3).should be_false
      klass.siblings?(2, 4).should be_false
      klass.siblings?(2, 5).should be_false      
    end
    
    it 'should be false for unrelated nodes' do
      klass.siblings?(1, 100).should be_false
      klass.siblings?(4, 6).should be_false
    end
    
    it 'should be true for left-right siblings' do
      klass.siblings?(2, 3).should be_true
      klass.siblings?(4, 5).should be_true
      klass.siblings?(100, 101).should be_true
    end

    it 'should be true for right-left siblings' do
      klass.siblings?(3, 2).should be_true
      klass.siblings?(5, 4).should be_true
      klass.siblings?(101, 100).should be_true
    end
  end
  
  describe 'left_child?' do
    it 'should be false for right nodes' do
      klass.left_child?(3).should be_false
      klass.left_child?(5).should be_false
      klass.left_child?(101).should be_false
    end

    it 'should be true for left nodes' do
      klass.left_child?(2).should be_true
      klass.left_child?(4).should be_true
      klass.left_child?(100).should be_true
    end
  end

  describe 'right_child?' do
    it 'should be false for left nodes' do
      klass.right_child?(2).should be_false
      klass.right_child?(4).should be_false
      klass.right_child?(100).should be_false
    end

    it 'should be true for right nodes' do
      klass.right_child?(3).should be_true
      klass.right_child?(5).should be_true
      klass.right_child?(101).should be_true
    end
  end
    
  describe 'visit_path_to_root' do
    it 'should work for the root' do
      root_path(1).should == [1]
    end

    it 'should work for a left path' do
      root_path(64).should == [64, 32, 16, 8, 4, 2, 1]
    end

    it 'should work for a right path' do
      root_path(63).should == [63, 31, 15, 7, 3, 1]
    end
    
    it 'should work for a zig-zag path' do
      root_path(1524).should == [1524, 762, 381, 190, 95, 47, 23, 11, 5, 2, 1]
    end

    # DRYes up testing for visit_path_to_root
    def root_path(node)
      nodes = []
      klass.visit_path_to_root(node) { |id| nodes << id }
      nodes
    end
  end
  
  describe 'node_update_path' do
    it 'should work for a left path' do
      klass.node_update_path(64).should ==
          [64, 65, 32, 33, 16, 17, 8, 9, 4, 5, 2, 3, 1]
    end

    it 'should work for a right path' do
      klass.node_update_path(63).should == [63, 62, 31, 30, 15, 14, 7, 6, 3, 2, 1]
    end
    
    it 'should work for a zig-zag path' do
      klass.node_update_path(1524).should == [1524, 1525, 762, 763, 381, 380,
          190, 191, 95, 94, 47, 46, 23, 22, 11, 10, 5, 4, 2, 3, 1]
    end    
  end
  
  describe 'instance methods' do
    before do
      @instance = HashTreeHelperWrap.new
    end
    
    describe 'nodes' do
      it 'should rely on capacity' do
        @instance.should_receive(:capacity).and_return 1024
        @instance.nodes.should == 2047
      end
    end
    
    describe '[]' do
      it 'should rely on node_hash' do
        @instance.should_receive(:capacity).and_return 1024
        @instance.should_receive(:node_hash).with(1025).and_return :node_value
        @instance[1].should == :node_value
      end
    end

    describe 'leaf_hash_unchecked' do
      it 'should rely on node_hash' do
        @instance.should_receive(:capacity).and_return 1024
        @instance.should_receive(:node_hash).with(1025).and_return :node_value
        @instance.leaf_hash_unchecked(1).should == :node_value
      end
    end
    
    describe 'root_hash' do
      it 'should rely on node_hash' do
        @instance.should_receive(:node_hash).with(1).and_return :node_value        
        @instance.root_hash.should == :node_value
      end
    end
    
    describe 'leaf_node_id' do
      it 'should rely on capacity' do
        @instance.should_receive(:capacity).and_return 1024
        @instance.leaf_node_id(1).should == 1025
      end
    end
    
    describe 'leaf_node?' do
      it 'should rely on capacity' do
        @instance.should_receive(:capacity).at_least(:once).and_return 1024
        @instance.leaf_node?(1).should be_false
        @instance.leaf_node?(1023).should be_false
        @instance.leaf_node?(1024).should be_true
        @instance.leaf_node?(2047).should be_true
      end
    end
    
    describe 'leaf_update_path' do
      it 'should rely on node_update_path' do
        @instance.should_receive(:capacity).and_return 1024
        @instance.should_receive(:node_update_path).with(1524).and_return :apath
        @instance.leaf_update_path(500).should == :apath
      end
    end
    
    describe 'correct_node_hash' do
      it 'should rely on node_hash' do
        left_hash = SpStore::Crypto.crypto_hash "2"
        right_hash = SpStore::Crypto.crypto_hash "3"
        @instance.should_receive(:node_hash).with(2).and_return left_hash
        @instance.should_receive(:node_hash).with(3).and_return right_hash
        @instance.correct_node_hash(1).should ==
            SpStore::Crypto.hash_for_tree_node(1, left_hash, right_hash)
      end
    end
  end
end
