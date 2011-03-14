# :nodoc: namespace
module SpStore

# :nodoc: namespace
module PChip

# Hacked together to get Hsin-Jung some test data.
module Interface
  # debugging only
  def self.load_root_command(root_hash)
    [[5].pack('C'), root_hash].join
  end

  def self.load_command(node_id, node_hash, entry, previous_parent_entry)
    [[0].pack('C'), [node_id].pack('N')[1, 3], node_hash,
     [entry, previous_parent_entry].pack('nn')].join
  end
  
  def self.verify_command(parent_entry, left_entry, right_entry)
    [1, right_entry, left_entry, parent_entry].pack('Cnnn')
  end
  
  def self.multi_verify_command(checks)
    [1 + checks.length].pack('C') + checks.reverse.map { |check|
      [check[:right], check[:left], check[:parent]].pack('nnn')
    }.join
  end
  
  # session_key won't be sent after the session table is up
  def self.sign_block_command(entry, nonce, session_key)
    [[6].pack('C'), session_key, nonce, [entry].pack('n')].join
  end
  
  # testcase generation
  def self.debug_cache_line(node_id, node_hash, verified, left, right)
    [[
      "\xCC".unpack('B*').first,
      [node_id].pack('N')[1, 3].unpack('B*').first[3, 21],
      node_hash.unpack('B*').first,
      (verified ? '1' : '0'), (left ? '1' : '0'), (right ? '1' : '0')
     ].join].pack('B*')
  end
  
  def self.one_shot_test_case
    left = SpStore::Crypto.crypto_hash 'left'
    right = SpStore::Crypto.crypto_hash 'right'
    wrong = SpStore::Crypto.crypto_hash 'wrong'
    root = SpStore::Crypto.hash_for_tree_node 1, left, right
    session_key = SpStore::Crypto.crypto_hash('session')[0, 16]
    nonce = SpStore::Crypto.crypto_hash('nonce_1')[0, 16]
    raw = [
      load_root_command(root),
      load_command(2, left, 1, 0),
      load_command(3, wrong, 2, 0),
      verify_command(0, 1, 2),
      load_root_command(root),
      load_command(3, right, 2, 0),
      load_command(2, left, 1, 0),
      verify_command(0, 1, 2),
      sign_block_command(1, nonce, session_key),
      "\xCB" + SpStore::Crypto.hmac_for_block_hash(2, left, nonce, session_key),
      debug_cache_line(1, root, true, true, true),
      debug_cache_line(2, left, true, false, false),
      debug_cache_line(3, right, true, false, false)
    ]
    max_length = raw.map(&:length).max
    raw.each { |command| command << "\0" * (max_length - command.length) }
    raw.map { |command| command.unpack('H*').first }
  end
end  # class SpStore::PChip::Interface
  
end  # namespace SpStore::Mocks
  
end  # namespace SpStore
