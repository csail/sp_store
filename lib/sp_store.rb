# Top-level namespace for the S-P store.
module SpStore
end  # namespace SpStore

require 'sp_store/interfaces/crypto.rb'
require 'sp_store/interfaces/store.rb'

require 'sp_store/storage/store_call_checker.rb'

require 'sp_store/mocks.rb'
require 'sp_store/mocks/bare_controller.rb'
require 'sp_store/mocks/ram_store.rb'
