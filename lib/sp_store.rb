# Top-level namespace for the S-P store.
module SpStore
end  # namespace SpStore

require 'sp_store/interfaces/controller.rb'
require 'sp_store/interfaces/crypto.rb'
require 'sp_store/interfaces/hash_tree.rb'
require 'sp_store/interfaces/store.rb'

require 'sp_store/merkle/hash_tree_helper.rb'

require 'sp_store/storage/store_call_checker.rb'

require 'sp_store/mocks.rb'
require 'sp_store/mocks/bare_controller.rb'
require 'sp_store/mocks/bare_hash_tree.rb'
require 'sp_store/mocks/factory_keys.rb'
require 'sp_store/mocks/ram_store.rb'
