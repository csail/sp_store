shared_examples_for 'a p chip' do
  describe 'boot_logic' do
    before do
      @boot_logic = @p_chip.boot_logic
      @puf_syndrome = @s_chip.puf_syndrome
      @endorsement_certificate = @s_chip.endorsement_certificate
    end
    
    it_should_behave_like 'a boot logic block'
  end
  
  describe 'after booting' do
    before do
      p = @p_chip.boot_logic
      s = @s_chip
      p.boot_finish(*s.boot(*p.boot_start(s.puf_syndrome,
                                          s.endorsement_certificate)))
    end

    describe 'node_cache' do
      let(:session_key) { SpStore::Crypto.hmac_key }
      let(:session_id) { 42 }
      
      before do
        encrypted_key = SpStore::Crypto.pki_encrypt(
            @s_chip.endorsement_certificate.public_key, session_key)
        processed_key = @p_chip.session_cache.process_key encrypted_key
        @p_chip.session_cache.load session_id, processed_key
        
        @cache = @p_chip.node_cache
        @tree = hash_tree
        @session_key = session_key
        @session_id = session_id
      end
      
      it_should_behave_like 'a node cache'
    end
    
    describe 'session_cache' do
      before do
        @cache = @p_chip.session_cache
        @public_key = @s_chip.endorsement_certificate.public_key
      end
      
      it_should_behave_like 'a session cache'
    end
  end
end
