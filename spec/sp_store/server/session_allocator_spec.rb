require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Server::SessionAllocator do
  
  let(:endorsement_key) { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:public_key)    { endorsement_key[:public] }  
  let(:session_key)   { SpStore::Crypto.hmac_key }
  let(:encrypted_key) { SpStore::Crypto.pki_encrypt public_key, session_key }
  let(:session_cache) { SpStore::PChip::SoftSessionCache.new 64 }

  before do
    session_cache.set_endorsement_key endorsement_key
    @allocator = SpStore::Server::SessionAllocator.new session_cache
  end
  
  describe 'new_id' do
    it 'should be non-negative' do
      @allocator.new_id(encrypted_key).should >= 0
    end
    it 'should be distinct' do
      current_session_ids = []
      (0...70).each{ current_session_ids << @allocator.new_id(encrypted_key) }
      current_session_ids.should == current_session_ids.uniq
    end    
  end

  let(:new_id) { @allocator.new_id encrypted_key }

  describe 'release_id' do
    it 'should reject negative session id' do
      lambda {
        @allocator.release_id(-1)
      }.should raise_error(ArgumentError)
    end 
    it 'should reject session id associated with a session that does not exit' do
      new_id_2 = new_id + 5
      lambda {
        @allocator.release_id(new_id_2)
      }.should raise_error(ArgumentError)
    end
    it 'should close a valid session' do
      lambda {
        @allocator.release_id(new_id)
      }.should_not raise_error
    end    
  end

  describe 'session_cache_entry' do
    it 'should reject negative session id' do
      lambda {
        @allocator.session_cache_entry(-1)
      }.should raise_error(ArgumentError)
    end
    it 'should reject session id associated with a session that does not exit' do
      @allocator.release_id(new_id)
      lambda {
        @allocator.session_cache_entry(new_id)
      }.should raise_error(ArgumentError)
    end
    it 'should be non-negative' do
      @allocator.session_cache_entry(new_id).should >= 0
    end
    it 'should be less than the cache size' do
      @allocator.session_cache_entry(new_id).should < 64
    end
    it 'should do cache replacement when cache is full' do
      (0...70).each{ @allocator.new_id(encrypted_key) }
      @allocator.session_cache_entry(64).should == @allocator.session_cache_entry(0)
      @allocator.session_cache_entry(65).should == @allocator.session_cache_entry(1)       
      @allocator.session_cache_entry(66).should == @allocator.session_cache_entry(2)       
    end
  end
end
