require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::RamStore do
  describe 'a 1024-block, 1024-block size store' do
    before do
      @store = SpStore::Mocks::RamStore.empty_store 1024, 1024
    end
    
    it_should_behave_like 'a block store'
  end
end
