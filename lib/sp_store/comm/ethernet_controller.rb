require 'ethernet'
# :nodoc: namespace
module SpStore
  
# :nodoc: namespace
module Communication

#  EthernetController controls the communication the FPGA p chip and the server
class EthernetController
  
  # eth_device: an Ethernet device name, e.g. 'eth0'
  # ether_type: 2-byte Ethernet packet type number, e.g. 0x88B5
  # dest_mac: FPGA MAC address in hex string, e.g. '0x001122334455'  
  def initialize( eth_device, ether_type, p_chip_mac )   
    @eth_device = eth_device
    @ether_type = ether_type
    @p_chip_mac = [p_chip_mac[2..-1]].pack('H*')
    @socket = nil
  end

  # Creates the Ethernet socket.
  def connect
    raise "Already connected." if @socket
    @socket = Ethernet.socket @eth_device, @ether_type
    @socket.connect @p_chip_mac
  end

  # Disconnects the Ethernet socket.
  #
  # The socket should have been connected previously.
  def disconnect
    raise "Not connected!" unless @socket
    @socket.close
    @socket = nil
  end
  
  # Outputs a packet.
  #
  # Arg:
  #   packet_data:: a string of raw bytes
  # Raises:
  #   RuntimeError:: if not connected
  def send(packet_data)
    raise "Not connected!" unless @socket
    #puts "Sending #{packet_data.unpack('H*').first}... "
    @socket.send packet_data
  end
  
  # Receives a packet
  #
  # Raises:
  #   RuntimeError:: if not connected
  def receive()
    raise "Not connected!" unless @socket
    #puts "Receiving... "
    data = @socket.recv
    #puts " #{data.unpack('H*').first} "
    #data
  end
    
end  # class SpStore::Communication::EthernetController

end  # namespace SpStore::Communication

end  # namespace SpStore
