# :nodoc: namespace
module SpStore

# :nodoc: namespace
module Mocks

# Software (untrusted) implementation of the S chip.
class SoftSChip
  def initialize(p_key, endorsement_key, endorsement_certificate, puf_syndrome,
                 root_hash)
    @p_key = p_key
    @sp_key = endorsement_key
    @puf_syndrome = puf_syndrome
    @endorsement_certificate = endorsement_certificate
    @root_hash = root_hash
  end
  
  def reset
    # TODO(pwnall): seems unnecessary, remove if it stays blank
  end
  
  def boot(encrypted_nonce, nonce_hmac)
    boot_nonce = Crypto.sk_decrypt(@p_key, encrypted_nonce)
    if Crypto.hmac(@p_key, boot_nonce) != nonce_hmac
      raise RuntimeError, 'Nonce HMAC check failed'
    end
    return @root_hash, Crypto.hmac(@p_key, [@root_hash, boot_nonce].join),
           Crypto.sk_encrypt(@p_key, Crypto.save_key_pair(@sp_key))
  end
  
  attr_reader :puf_syndrome
  attr_reader :endorsement_certificate
end  # class SpStore::Mocks::SoftSChip
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
