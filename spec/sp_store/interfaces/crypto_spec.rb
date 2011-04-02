require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Crypto do
  describe 'nonce' do
    it 'should be random' do
      Array.new(1000) { SpStore::Crypto.nonce }.uniq.should have(1000).nonces
    end
  end
  
  describe 'hmac_key' do
    it 'should be random' do
      Array.new(1000) { SpStore::Crypto.hmac_key }.uniq.should have(1000).keys
    end
    
    let(:key) { SpStore::Crypto.hmac_key }
    it 'should work with hmac' do
      SpStore::Crypto.hmac(key, 'data').should ==
          SpStore::Crypto.hmac(key, 'data')
    end
    
    let(:test_data) { (1..65).map { |i| (i ^ 0x3F) % 255 }.pack('C*') }
    let(:test_data2) { (1..65).map { |i| (i ^ 0x19) % 255 }.pack('C*') }
    
    it 'should hmac different data to different signatures' do
      SpStore::Crypto.hmac(key, test_data).should_not ==
          SpStore::Crypto.hmac(key, test_data2)
    end

    it 'should hmac consistently' do
      SpStore::Crypto.hmac(key, test_data).should ==
          SpStore::Crypto.hmac(key, test_data)
    end
    
    let(:nonce) { SpStore::Crypto.nonce }
    it 'should hmac data blocks consistently' do
      SpStore::Crypto.hmac_for_block(1, test_data, nonce, key).should ==
          SpStore::Crypto.hmac_for_block(1, test_data, nonce, key)
    end
    it 'should hmac same block with different data to different signatures' do
      SpStore::Crypto.hmac_for_block(1, test_data, nonce, key).should_not ==
          SpStore::Crypto.hmac_for_block(1, test_data.reverse, nonce, key)
    end
    it 'should hmac different blocks with same data to different signatures' do
      SpStore::Crypto.hmac_for_block(1, test_data, nonce, key).should_not ==
          SpStore::Crypto.hmac_for_block(2, test_data, nonce, key)
    end
    it 'should hmac different nonces to different signatures' do
      nonce2 = SpStore::Crypto.nonce
      SpStore::Crypto.hmac_for_block(1, test_data, nonce, key).should_not ==
          SpStore::Crypto.hmac_for_block(1, test_data, nonce2, key)
    end
  end
  
  describe 'pki' do
    let(:key) { SpStore::Crypto.key_pair }
    let(:test_data) { (1..65).map { |i| (i ^ 0x3F) % 255 }.pack('C*') }
    
    it 'should generate random keys' do
      key2 = SpStore::Crypto.key_pair
      SpStore::Crypto.save_key_pair(key2).should_not ==
          SpStore::Crypto.save_key_pair(key)
    end
    
    let(:encrypted_data) { SpStore::Crypto.pki_encrypt key[:public], test_data }
    it 'should decrypt what it encrypts' do
      SpStore::Crypto.pki_decrypt(key[:private], encrypted_data).should ==
          test_data
    end
    
    let(:saved_key) { SpStore::Crypto.save_key_pair key }
    it 'should load saved keys' do
      SpStore::Crypto.key_pair(saved_key).inspect.should == key.inspect
    end
  end
  
  describe 'sk_key' do
    it 'should be random' do
      Array.new(1000) { SpStore::Crypto.sk_key }.uniq.should have(1000).keys
    end
    
    let(:key) { SpStore::Crypto.sk_key }
    let(:test_data) { (1..65).map { |i| (i ^ 0x3F) % 255 }.pack('C*') }
    let(:encrypted_data) { SpStore::Crypto.sk_encrypt key, test_data }

    it 'should decrypt what it encrypts' do
      SpStore::Crypto.sk_decrypt(key, encrypted_data).should == test_data
    end
  end
  
  describe 'cert' do
    let(:ca_dn) { { 'CN' => 'RSpec CA', 'C' => 'US' } }
    let(:dn) { { 'CN' => 'RSpec Cert', 'C' => 'US' } }
    let(:ca_key) { SpStore::Crypto.key_pair }
    let(:ca2_key) { SpStore::Crypto.key_pair }
    let(:ca_cert) { SpStore::Crypto.cert ca_dn, 1, ca_key }
    let(:ca2_cert) { SpStore::Crypto.cert ca_dn, 1, ca2_key }
    let(:key) { SpStore::Crypto.key_pair }
    let(:cert) { SpStore::Crypto.cert dn, 1, ca_key, ca_cert, key[:public] }
    
    it 'should match the given public key' do
      cert.public_key.inspect.should == key[:public].inspect
    end
    
    it 'should verify with the CA' do
      SpStore::Crypto.verify_cert(cert, [ca_cert]).should be_true
    end

    it 'should not verify with a different CA' do
      SpStore::Crypto.verify_cert(cert, [ca2_cert]).should be_false
    end

    it 'should verify with the CA public key' do
      SpStore::Crypto.verify_cert_ca_key(cert, ca_key[:public]).should be_true
    end

    it 'should not verify with a different CA' do
      SpStore::Crypto.verify_cert_ca_key(cert, ca2_key[:public]).should be_false
    end
    
    let(:saved_cert) { SpStore::Crypto.save_cert cert }
    it 'should load a saved certificate' do
      SpStore::Crypto.load_cert(saved_cert).inspect.should == cert.inspect
    end
  end
end
