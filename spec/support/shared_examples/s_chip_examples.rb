shared_examples_for 'an s chip' do
  describe 'puf syndrome' do
    it 'should return a non-empty string' do
      @s_chip.puf_syndrome.length.should > 0
    end
  end
  
  describe 'endorsement_certificate' do
    it 'should have a public key' do
      @s_chip.endorsement_certificate.public_key.should_not be_nil
    end
  end
  
  describe 'reset' do
    it 'should not crash' do
      lambda {
        @s_chip.reset
      }.should_not raise_error
    end
  end
  
  describe 'boot' do
    it 'should accept a good hmac' do
      lambda {
        @s_chip.boot @encrypted_nonce, @boot_nonce_hmac
      }.should_not raise_error
    end
    
    it 'should not accept a broken hmac' do
      lambda {
        @s_chip.boot @encrypted_nonce, @boot_nonce_hmac.reverse
      }.should raise_error(RuntimeError)
    end
    
    it 'result should be accepted by paired p chip' do
      lambda {
        @p_chip.boot_logic.
                boot_finish(*@s_chip.boot(@encrypted_nonce, @boot_nonce_hmac))
      }.should_not raise_error
    end
  end
end
