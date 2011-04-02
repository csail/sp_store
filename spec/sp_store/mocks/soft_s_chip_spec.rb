require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::SoftSChip do
  let(:p_key) { SpStore::Crypto.sk_key }
  let(:puf_syndrome) { SpStore::Crypto.crypto_hash p_key }
  let(:endorsement_key) { SpStore::Crypto.key_pair }
  let(:ca_keys) { SpStore::Mocks::FactoryKeys.ca_keys }
  let(:endorsement_certificate) do
    dn = { 'CN' => 'Mock P Chip' }
    SpStore::Crypto.cert dn, 1, ca_keys, SpStore::Mocks::FactoryKeys.ca_cert,
                         endorsement_key[:public]
  end
  let(:root_hash) { SpStore::Crypto.crypto_hash 'root' }
  
  let(:s_chip) do
    SpStore::Mocks::SoftSChip.new p_key, endorsement_key,
        endorsement_certificate, puf_syndrome, root_hash
  end
  let(:p_chip) do
    SpStore::Mocks::SoftPChip.new p_key, ca_keys[:public], :cache_size => 64,
        :capacity => 1024, :session_cache_size => 64
  end
  
  before do
    @s_chip = s_chip
    @p_chip = p_chip
    @encrypted_nonce, @boot_nonce_hmac =
        p_chip.boot_logic.boot_start puf_syndrome, endorsement_certificate
    @boot_nonce = SpStore::Crypto.sk_decrypt p_key, @encrypted_nonce
  end
  
  it_should_behave_like 'an s chip'
  
  describe 'boot result' do
    before do
      @boot_hash, @boot_hmac, @boot_encrypted_key =
          @s_chip.boot @encrypted_nonce, @boot_nonce_hmac
    end
    
    it 'should have the root hash' do
      @boot_hash.should == root_hash
    end
    
    it 'should hmac the root hash and boot nonce' do
      @boot_hmac.should == SpStore::Crypto.hmac(p_key, root_hash + @boot_nonce)
    end
    
    it 'should have the encrypted private key' do
      key_material = SpStore::Crypto.sk_decrypt p_key, @boot_encrypted_key
      key = SpStore::Crypto.key_pair(key_material)
      key[:private].inspect.should == endorsement_key[:private].inspect
      key[:public].inspect.should == endorsement_key[:public].inspect
    end
  end
end
