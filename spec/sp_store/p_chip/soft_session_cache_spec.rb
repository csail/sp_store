require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::PChip::SoftSessionCache do
  let(:endorsement_key) { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:public_key) { endorsement_key[:public] }
  let(:cache) { SpStore::PChip::SoftSessionCache.new 64 }

  before do
    cache.set_endorsement_key endorsement_key
    @public_key = public_key
    @cache = cache
  end
  it_should_behave_like 'a session cache'

  let(:session_key) { SpStore::Crypto.hmac_key }
  let(:encrypted_key) { SpStore::Crypto.pki_encrypt public_key, session_key }
  let(:processed_key) { cache.process_key encrypted_key }

  describe 'load' do
    before do
      @cache.load 0, processed_key
    end
    
    it 'should store the key correctly' do
      @cache.session_key(0).should == session_key
    end
  end
end
