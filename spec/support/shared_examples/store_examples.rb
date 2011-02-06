shared_examples_for 'a block in a block store' do
  let(:block_data) { @store.read_block block_number }
  it 'should have block_size bytes' do
    block_data.length.should == @store.block_size
  end
  it 'should be zeroed out initially' do
    block_data.should == "\0" * block_data.length
  end
  it 'should retain data' do
    @store.write_block block_number, test_pattern
    @store.read_block(block_number).should == test_pattern
  end
  
  def test_pattern
    (0...(@store.block_size)).map { |i| (block_number ^ i) % 256 }.pack('C*')
  end
end

shared_examples_for 'a block store' do
  it 'should have a positive number of blocks' do
    @store.blocks.should > 0
  end
  
  it 'should have a power-of-2 block size' do
    @store.block_size.should > 0
    @store.block_size.should ==
        2 ** (Math.log(@store.block_size) / Math.log(2)).to_i
  end
  
  describe 'first block' do
    let(:block_number) { 0 }
    it_should_behave_like 'a block in a block store'
  end
  
  describe 'last block' do
    let(:block_number) { @store.blocks - 1 }
    it_should_behave_like 'a block in a block store'
  end
  
  describe 'a block in the middle' do
    let(:block_number) { @store.blocks / 2 - 1 }
    it_should_behave_like 'a block in a block store'
  end
end
