# :nodoc: namespace
module SpStore::Mocks

# Keys meant for development.
module FactoryKeys
  # Development manufacturer CA.
  #
  # It is used to sign Endorsement Keys for development boards.
  def self.ca_cert
    return @ca_cert if @ca_cert
    @ca_cert = File.open(dev_ca_file, 'rb') do |f|
      SpStore::Crypto.load_cert f.read
    end
  end
  @ca_cert = nil

  # Key pair for the development manufacturer CA.
  def self.ca_keys
    return @ca_keys if @ca_keys
    @ca_keys = File.open(dev_ca_keys_file, 'rb') do |f|
      SpStore::Crypto.key_pair f.read
    end
  end
  @ca_keys = nil
  
  # Distinguished Name (DN) for the CA.
  def self.ca_dn
    {
      'CN' => 'S-P Store Dev CA',
      'C' => 'US'
    }
  end
  
  # Creates a new set of development keys.
  #
  # This should only be done by gem authors. Changing the dev keys in a system
  # will make it reject existing dev boards.
  def self.regenerate
    @ca_keys = @ca_cert = nil
    keys = SpStore::Crypto.key_pair
    File.open dev_ca_keys_file, 'wb' do |f|
      f.write SpStore::Crypto.save_key_pair(keys)
    end
    cert = SpStore::Crypto.cert ca_dn, 3650, keys
    File.open dev_ca_file, 'wb' do |f|
      f.write SpStore::Crypto.save_cert(cert)
    end
  end
  
  # Path to development CA keys.
  def self.dev_ca_keys_file
    File.join dev_files_path, 'dev_ca_keys.der'
  end

  # Path to development CA certicate.
  def self.dev_ca_file
    File.join dev_files_path, 'dev_ca.crt'
  end
  
  # Path to development CA certificate and keys.
  def self.dev_files_path
    File.expand_path File.dirname(__FILE__)
  end
end

end  # namespace SpStore::Mocks
