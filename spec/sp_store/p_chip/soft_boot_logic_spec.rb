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
  let(:root_hash) { SpStore::Crypto.crypto_hash 'root' }
  
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
      @root_hash_hmac = SpStore::Crypto.hmac p_key, root_hash + @boot_nonce
    end
    
    it 'resulting hmac should match the boot nonce' do
      @nonce_hmac.should == SpStore::Crypto.hmac(p_key, @boot_nonce)
    end
    
    describe 'boot_finish' do
      let(:encrypted_key) do
        SpStore::Crypto.sk_encrypt p_key,
            SpStore::Crypto.save_key_pair(endorsement_key)
      end
      
      it 'should call booted' do
        # Hack the endorsement key to implement == correctly and pass the spec.
        class <<endorsement_key
          def ==(other)
            other && self.inspect == other.inspect
          end
        end
        observer.should_receive(:booted).with(root_hash, endorsement_key)
        boot_logic.boot_finish root_hash, @root_hash_hmac, encrypted_key
      end
      
      it 'should reject the wrong key' do
        fake_encrypted_key = SpStore::Crypto.sk_encrypt p_key,
            SpStore::Crypto.save_key_pair(ca_keys)
        lambda {
          boot_logic.boot_finish root_hash, @root_hash_hmac, fake_encrypted_key
        }.should raise_error(RuntimeError)
      end

      it 'should crash after reset' do
        boot_logic.reset
        lambda {
          boot_logic.boot_finish root_hash, @root_hash_hmac, encrypted_key
        }.should raise_error(RuntimeError)
      end
    end
  end
  
  describe 'reset' do
    it 'should call the observer reset' do
      observer.should_receive(:reset)
      lambda {
        boot_logic.reset
      }.should_not raise_error
    end
  end
end
