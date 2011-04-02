shared_examples_for 'a boot logic block' do
  describe 'reset' do
    it 'should not raise errors' do
      lambda {
        @boot_logic.reset
      }.should_not raise_error
    end
  end
  
  describe 'boot_start' do
    it 'should accept a correct syndrome and certificate' do
      lambda {
        @boot_logic.boot_start @puf_syndrome, @endorsement_certificate
      }.should_not raise_error
    end
    
    it 'should reject an incorrect syndrome' do
      lambda {
        @boot_logic.boot_start @puf_syndrome.reverse, @endorsement_certificate
      }.should raise_error(RuntimeError)
    end
    
    it 'should reject an incorrect certificate' do
      fake_ca_keys = SpStore::Crypto.key_pair
      fake_ca_cert = SpStore::Crypto.cert @endorsement_certificate.issuer, 3650,
                                          fake_ca_keys
      fake_keys = SpStore::Crypto.key_pair
      fake_cert = SpStore::Crypto.cert @endorsement_certificate.subject, 1,
          fake_ca_keys, fake_ca_cert, fake_keys[:public]
      lambda {
        @boot_logic.boot_start @puf_syndrome, fake_cert
      }.should raise_error(RuntimeError)
    end
    
    it 'should produce results accepted by the s chip' do
      lambda {
        @s_chip.boot(*@boot_logic.boot_start(@puf_syndrome,
                                             @endorsement_certificate))
      }.should_not raise_error
    end
  end
end
