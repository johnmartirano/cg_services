require 'set'
require 'thread'
require 'monitor'

module CgServiceClient
  # In-memory, threadsafe cache for use with Typhoeus.  Objects are
  # removed from the cache according to their cache_timeout (set at
  # insertion).
  class Cache
    include MonitorMixin

    DEFAULT_AUTOPRUNE_PERIOD_IN_SEC = 30

    Entry = Struct.new(:value, :timeout)

    attr_reader :entries

    def initialize(autoprune_period = DEFAULT_AUTOPRUNE_PERIOD_IN_SEC)
      super()                   # required to init MonitorMixin
      @entries = Hash.new
      @entries.extend(MonitorMixin)

      if autoprune_period > 0
        start_autoprune(autoprune_period)
      end
    end

    # Insert +value+ to the cache.
    #
    # @param [Object] key the key
    # @param [Object] value the value
    #
    # @param [Integer] timeout time in seconds before this key/value
    # will be removed from the cache (resolution is seconds)
    def set(key, value, timeout)
      entries.synchronize do
        entries.store(key, Entry.new(value, Time.now.to_i+timeout))
      end
    end

    # Get the value stored at +key+.  If there is no value, nil will
    # be returned.  If or the value's timeout has passed, it will be
    # deleted from the cache and nil will be returned.
    #
    # @param [Object] key
    # @return [Object] the previously stored value, or nil
    def get(key)
      entries.synchronize do
        if entry = entries.fetch(key, nil)
          if expired?(entry)
            entries.delete(key)
            nil
          else
            entry[:value]
          end
        end
      end
    end

    # Prune the cache, removing all entries past timeout.
    #
    # FIXME: this iterates through each entry.  Could use a heap,
    # priority queue, or other means to maintain the cache entries
    # sorted by expiration time.  Then just pull the from that,
    # deleting from the cache.  Bonus: you know when the next entry
    # will expire and can sleep just that much (but that fact may
    # change if another entry is added while you were sleeping...)
    #
    # @see https://github.com/Kanwei/Algorithms/
    def prune
      entries.synchronize do
        # get(key) has side effect of deleting expired keys
        entries.each_key { |key| get(key) }
      end
    end

    # Start the autopruning thread to autoprune cache entries if it is
    # not running.
    def start_autoprune(period = DEFAULT_AUTOPRUNE_PERIOD_IN_SEC)
      self.synchronize do
        return if @thread

        @thread = Thread.new do
          loop do
            sleep period
            prune
          end
        end
      end
    end

    # Stop the autopruning thread if it is running.
    def stop_autoprune
      self.synchronize do
        if @thread
          @thread.terminate
          @thread = nil
        end
      end
    end

    protected

    def expired?(entry)
      Time.now.to_i > entry[:timeout]
    end
  end
end
