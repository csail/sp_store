# The examples expect a tree associated with the cache.
shared_examples_for 'a node cache' do
  describe 'capacity' do
    let(:capacity) { @cache.capacity }
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end

  describe 'leaf_count' do
    let(:leaf_count) { @cache.leaf_count }
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end
  
  describe 'load' do
    
  end
end
