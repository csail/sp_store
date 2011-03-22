# :nodoc: namespace
module SpStore

# :nodoc: namespace
module Mocks

# Software (untrusted) chip factory.
class SoftFactory
  # Creates a factory
  def initialize(keys, cert)
    @keys = keys
    @cert = cert
  end
  
  # Convenience method that creates a factory off the development keys.
  def self.dev_factory
    self.new FactoryKeys.ca_keys, FactoryKeys.ca_cert
  end
  
  def sp_pair
    p_chip = SoftPChip.new
    s_chip = SoftSChip.new
    return p_chip, s_chip
  end
  
  def ca_cert
    @cert
  end
end  # class SpStore::Mocks::SoftPChip
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
