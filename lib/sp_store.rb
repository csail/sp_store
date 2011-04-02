# Top-level namespace for the S-P store.
module SpStore
end  # namespace SpStore

require 'sp_store/interfaces/controller.rb'
require 'sp_store/interfaces/crypto.rb'
require 'sp_store/interfaces/factory.rb'
require 'sp_store/interfaces/hash_tree.rb'
require 'sp_store/interfaces/p_chip.rb'
require 'sp_store/interfaces/s_chip.rb'
require 'sp_store/interfaces/store.rb'

require 'sp_store/merkle/hash_tree_call_checker.rb'
require 'sp_store/merkle/hash_tree_helper.rb'

require 'sp_store/p_chip/interface.rb'
require 'sp_store/p_chip/soft_boot_logic.rb'
require 'sp_store/p_chip/soft_node_cache.rb'
require 'sp_store/p_chip/soft_session_cache.rb'

require 'sp_store/server/controller.rb'
require 'sp_store/server/session_allocator.rb'

require 'sp_store/storage/store_call_checker.rb'

require 'sp_store/mocks.rb'
require 'sp_store/mocks/bare_controller.rb'
require 'sp_store/mocks/factory_keys.rb'
require 'sp_store/mocks/ram_store.rb'
require 'sp_store/mocks/soft_hash_tree.rb'
require 'sp_store/mocks/soft_p_chip.rb'
require 'sp_store/mocks/soft_s_chip.rb'
