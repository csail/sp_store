require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::PChip::SoftSessionCache do
  before do
    @key = SpStore::Mocks::FactoryKeys.ca_keys
    @cache = SpStore::PChip::SoftSessionCache.new 64, @key
  end

  it_should_behave_like 'a session cache'
  
  let(:session_key) { SpStore::Crypto.hmac_key }
  let(:encrypted_key) { SpStore::Crypto.pki_encrypt @key[:public], session_key }
  let(:processed_key) { @cache.process_key encrypted_key }

  describe 'load' do
    before do
      @cache.load 0, processed_key
    end
    
    it 'should store the key correctly' do
      @cache.session_key(0).should == session_key
    end
  end
end
