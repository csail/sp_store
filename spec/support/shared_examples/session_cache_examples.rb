shared_examples_for 'a session cache' do
  describe 'capacity' do
    let(:capacity) { @cache.capacity }
    it 'should be positive' do
      capacity.should > 0
    end
    it 'should be a power of 2' do
      capacity.should == 2 ** (Math.log(capacity) / Math.log(2)).to_i
    end
  end

  let(:session_key) { SpStore::Crypto.hmac_key }
  let(:encrypted_key) { SpStore::Crypto.pki_encrypt @public_key, session_key }
  let(:processed_key) { @cache.process_key encrypted_key }

  describe 'process_key' do
    it 'should work for a properly encrypted session key' do
      processed_key.should_not be_nil
    end
    
    it 'should fail on improperly formatted keys' do
      lambda {
        @cache.process_key encrypted_key.reverse
      }.should raise_error
    end
  end

  describe 'load' do
    it 'should work for proper entries' do
      lambda {
        @cache.load 0, processed_key
      }.should_not raise_error
    end
    
    it 'should reject negative entry numbers' do
      lambda {
        @cache.load -1, processed_key
      }.should raise_error
    end

    it 'should reject large entry numbers' do
      lambda {
        @cache.load capacity + 1, processed_key
      }.should raise_error
    end
  end
end
