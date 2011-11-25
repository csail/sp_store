shared_examples_for 'a store controller' do
  let(:ecert) { @controller.endorsement_certificate }
  it 'should have an endorsement certificate' do
    ecert.should_not be_nil
    ecert.public_key.should_not be_nil
  end
  
  describe 'session' do  
    let(:key) { SpStore::Crypto.hmac_key }
    let(:session) do
      encrypted_key = SpStore::Crypto.pki_encrypt ecert.public_key, key
      @controller.session encrypted_key
    end
    
    it 'should return a positive block size' do
      session.block_size.should > 0
    end
    
    it 'should return a positive number of blocks' do
      session.blocks.should > 0
    end
    
    let(:nonce) { SpStore::Crypto.nonce }
    it 'should HMAC read operations' do
      data, hmac = session.read_block 0, nonce
      hmac.should == SpStore::Crypto.hmac_for_block(node_id(0), data, nonce, key)
    end
    
    let(:pattern) do
      (0...session.block_size).map { |i| (i ^ 0x3E) % 255}.pack('C*')
    end
    it 'should HMAC write operations' do
      hmac = session.write_block 0, pattern, nonce
      hmac.should == SpStore::Crypto.hmac_for_block(node_id(0), pattern, nonce, key)
    end
    
    describe 'after a write' do
      before do
        session.write_block 0, pattern, nonce        
      end
      
      it 'should persist the write' do
        data, hmac = session.read_block 0, nonce  
        data.should == pattern
      end
    end
  end
end
