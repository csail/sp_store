# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Software implementation of the P chip's hash engine.
class SoftHashEngine
  def hash_block(data)
    Crypto.crypto_hash data
  end
end  # class SpStore::PChip::SoftHashEngine 
  
end  # namespace SpStore::PChip
  
end  # namespace SpStore
