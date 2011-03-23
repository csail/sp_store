# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Software (untrusted) implementation of the P chip's boot logic.
class SoftBootLogic
  # Instantiates a software model of the P chip's boot logic module.
  #
  # Args:
  #   p_key:: the P chip's symmetric key; was generated during the manufacturing
  #           process
  #   ca_public_key:: the public key of the S-P chip pair's manufacturer root
  #                   CA; this is burned in the P chip's ROM
  def initialize(p_key, ca_public_key)
    @p_key = p_key
    @ca_pubkey = ca_public_key
  end

  def reset
    @session_cache = new SpStore::PChip::SessionTable session_cache_size
    @boot_nonce = nil
    @root_hash = nil
    @endorsement_key = nil
  end
  
  def boot_start(puf_syndrome, endorsement_certificate)
    # State check.
    raise RuntimeError, 'Already called boot_start' if @boot_nonce

    # Argument check.
    if Crypto.crypto_hash(puf_syndrome) != @p_key
      raise RuntimeError, 'Invalid PUF syndrome'
    end
    if endorsement_certificate.public_key != @ca_pubkey
      raise RuntimeError, 'Invalid Endorsement Certificate'
    end
    @endorsement_certificate = endorsement_certificate

    # State transition.
    @boot_nonce = Crypto.nonce
    
    return Crypto.sk_encrypt(@p_key, @boot_nonce),
           Crypto.hmac(@p_key, @boot_nonce)
  end
  
  def boot_finish(root_hash, state_hmac, encrypted_endorsement_key)
    # State check.
    raise RuntimeError, 'Already called boot_finish' if @root_hash

    # Argument check.
    if Crypto.hmac(@p_key, [root_hash, @boot_nonce].join) != state_hmac
      raise RuntimeError, 'State HMAC check failed'
    end
    endorsement_key = Crypto.key_pair(
        Crypto.sk_decrypt(@p_key, encrypted_endorsement_key))
    if endorsement_key[:public] != @endorsement_certificate.public_key
      raise RuntimeError, 'Endorsement key does not match certificate'
    end
    
    # State transition.
    @endorsement_key = endorsement_key
    @root_hash = root_hash
  end
  
  # 
  attr_reader :root_hash
  attr_reader :endorsement_key
end  # class SpStore::PChip::SoftBootLogic
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
