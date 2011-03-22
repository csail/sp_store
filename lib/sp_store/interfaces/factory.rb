# :nodoc: namespace
module SpStore

# API implemented by a chip factory.
module Factory
  # Produces a S-P chip pair.
  #
  # Returns a P chip and an S chip that are paired together. The P chip obeys
  # the PChip interface, and the S chip obeys the SChip interface.
  def sp_pair()
    
  end
  
  # The factory's root certificate.
  def ca_cert
    
  end
end  # class SpStore::SChip

end  # namespace SpStore
