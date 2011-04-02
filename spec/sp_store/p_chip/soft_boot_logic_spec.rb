require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::PChip::SoftBootLogic do
  let(:p_key) { SpStore::Crypto.sk_key }
  let(:puf_syndrome) { SpStore::Crypto.crypto_hash p_key }
  let(:endorsement_key) { SpStore::Crypto.key_pair }
  let(:ca_keys) { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:endorsement_certificate) do
    dn = { 'CN' => 'Mock P Chip' }
    SpStore::Crypto.cert dn, 1, ca_keys, SpStore::Mocks::FactoryKeys.ca_cert,
                         endorsement_key[:public]
  end
  
  let(:observer) do
    observer = mock('observer')
    observer.stub!(:reset)
    observer.stub!(:booted)
    observer
  end
  let(:boot_logic) do
    SpStore::PChip::SoftBootLogic.new p_key, ca_keys[:public], observer
  end
  let(:s_chip) do
    SpStore::Mocks::SoftSChip.new p_key, endorsement_key,
        endorsement_certificate, puf_syndrome, root_hash
  end

  before do
    @puf_syndrome = puf_syndrome
    @endorsement_certificate = endorsement_certificate
    @boot_logic = boot_logic
    @s_chip = s_chip
  end
  
  it_should_behave_like 'a boot logic block'
  
  describe 'after boot_start' do
    before do
      @encrypted_nonce, @nonce_hmac =
          boot_logic.boot_start puf_syndrome, endorsement_certificate
      @boot_nonce = SpStore::Crypto.sk_decrypt p_key, @encrypted_nonce
    end
    
    it 'resulting hmac should match the boot nonce' do
      @nonce_hmac.should == SpStore::Crypto.hmac(p_key, @boot_nonce)
    end
    
    let(:root_hash) { SpStore::Crypto.crypto_hash 'root' }
  end
end
