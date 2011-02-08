require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Mocks::FactoryKeys do
  let(:ca_cert) { SpStore::Mocks::FactoryKeys.ca_cert }
  describe 'ca_cert' do
    it 'should have a public key' do
      ca_cert.public_key.should_not be_nil
    end
  end

  let(:ca_keys) { SpStore::Mocks::FactoryKeys.ca_keys }
  describe 'ca_keys' do
    it 'should have a private key' do
      ca_keys[:private].should_not be_nil
    end
    it 'should have a public key matching the CA certificate' do
      ca_keys[:public].inspect.should == ca_cert.public_key.inspect
    end
  end
end
