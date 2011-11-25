# :nodoc: namespace
module SpStore
  
# :nodoc: namespace
module Server

# Glues all the S-P store components together.
# SessionAllocator allocates & releases sessions and controls session cache in the p-chip
class SessionAllocator
  # @cache is the session cache in P chip
  # @cache_tags stores the currently cached session_ids
  # @session_table stores the (session_id => processed_key) pairs for all sessions
  # @max_session_id keeps track of the maximum value of the session_ids 
  # that exist in the session cache or the unused_session_ids array  
  def initialize(session_cache)
    @cache                   = session_cache
    @cache_tags              = Array.new session_cache.capacity, nil
    @session_table           = Hash.new
    @unused_session_ids      = (0...session_cache.capacity).to_a
    @max_session_id          = session_cache.capacity-1;   
  end
  
  # allocate a new session 
  def new_id(encrypted_session_key)
    if @unused_session_ids.empty? #session cache is full 
      @max_session_id += 1
      session_id = @max_session_id      
    else
      session_id = @unused_session_ids.shift
    end
    @session_table[session_id] = @cache.process_key encrypted_session_key    
    session_id
  end
  
  # invalidate a closed session
  def release_id(session_id)
    _check_session_id session_id
    @session_table.delete session_id
    @unused_session_ids << session_id
  end
  
  # load session and return the session cache entry_id
  def session_cache_entry(session_id)
    _check_session_id session_id
    cache_entry_id = session_id.modulo @cache.capacity
    load_session cache_entry_id, session_id
    cache_entry_id
  end
  
  # load the session into cache if the session is not cached
  def load_session(cache_entry_id, session_id)
    if @cache_tags[cache_entry_id] != session_id  # the session is not cached yet
      @cache.load cache_entry_id, @session_table[session_id]
      @cache_tags[cache_entry_id] = session_id
    end
  end
  private :load_session  
  
  def _check_session_id(session_id)
    if session_id < 0
      raise ArgumentError, "Invalid session id #{session_id}"
    elsif @session_table[session_id] == nil
      raise ArgumentError, "Session #{session_id} does not exist"
    end
  end
  private :_check_session_id  
  
end  # class SpStore::Server::SessionAllocator
  
end  # namespace SpStore::Server

end  # namespace SpStore
