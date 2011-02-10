# :nodoc: namespace
module SpStore
  
# API implemented by a P chip (powerful processor without non-volatile state).
module PChip
  # The number of data blocks (hash tree leaves) that supported by this P chip.
  def capacity
    
  end
  
  # The first step of the S-P boot sequence.
  #
  # This method can only be called once, right after the P chip is powered on.
  # It should be followed by a call to boot_finish.
  #
  # Args:
  #   puf_syndrome:: the information needed to recover the P chip's symmetric
  #                  key out of its PUF
  #
  # Returns a randomly generated nonce, and the nonce's HMAC, keyed under the
  # P chip's symmetric key.
  #
  # Raises:
  #   RuntimeError:: if boot_start was already called
  #   RuntimeError:: if the HMAC doesn't match the system state (root_hash)
  def boot_start(puf_syndrome)
    
  end
  
  # The last step of the S-P boot sequence.
  #
  # This method can only be called once, after boot_start has been called. After
  # the method completes, the P chip can serve requests.
  #
  # Args:
  #   root_hash:: the storage root key
  #   state_hmac:: HMAC over the P chip's nonce and root hash, keyed with the
  #                P chip's symmetric key
  #   endorsement_key:: the private endorsement key for the S-P chip pair,
  #                     encrypted with the P chip's symmetric key
  #
  # Returns self.
  #
  # Raises:
  #   RuntimeError:: if boot_finish was alredy called, or boot_start wasn't
  #                  called yet
  #   RuntimeError:: if the HMAC doesn't match the system state (root_hash)
  def boot_finish(root_hash, state_hmac, endorsement_key)
    
  end
  
  # Establishes a session between a S-P store client and the P chip.
  #
  # Args:
  #   session_id:: a low number specifying the key slot used by this session
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the S-P chip pair's' public
  #                           Endorsement Key
  #
  # Returns the HMAC of the given nonce under the session key.
  def open_session(session_id, encrypted_session_key)
    session_key = Crypto.pki_decrypt @endorsement_key[:private],
                                     encrypted_session_key
    @session_keys[session_id] = session_key
    Crypto.hmac session_key, nonce
  end
  
  # Tears down a session between a trusted-storage client and the FPGA.
  #
  # Returns self.
  def close_session(session_id)
    @session_keys.delete session_id
    self
  end
end  # class SpStore::PChip

end  # namespace SpStore
