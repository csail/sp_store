require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe SpStore::Communication::EthernetController do

  let(:eth_device) { Ethernet::Devices.all.sort.first }
  let(:eth_type) { 0x08B5 }
  let(:p_chip_mac) { '0x001122334455' }
  
  before { @connector = SpStore::Communication::EthernetController.new eth_device, eth_type, p_chip_mac }

  describe 'connected to p_chip' do
    before { @connector.connect   }
    after { @connector.disconnect }
    it 'should be able to send a packet' do
      @connector.send 'Shell test packet'
    end
    it 'should not connect again' do
      lambda {
        @connector.connect
      }.should raise_error(RuntimeError)
    end
  end

  describe 'disconnected' do
    it 'should not send packets' do
      lambda {
        @connector.send 'Will never go out'
      }.should raise_error(RuntimeError)
    end
  end
  
end
