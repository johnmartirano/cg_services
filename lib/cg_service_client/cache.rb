require 'set'
require 'thread'
require 'monitor'

module CgServiceClient
  class Cache
    CACHE_EXPIRY_INTERVAL_IN_SEC = 30
    @entries = Hash.new
    @entries_monitor = Monitor.new

    def set(key, value, timeout)
      @entries_monitor.synchronize do
        Cache.entries.store(key, Entry.new(value, Time.now.to_i+timeout))
      end
    end

    def get(key)
      @entries_monitor.synchronize do
        Cache.entries.fetch(key, nil).value
      end
    end

    class Entry
      attr_reader :value, :timeout

      def initialize(value, timeout)
        @value = value
        @timeout = timeout
      end
    end

    Thread.new do
      loop do
        sleep CACHE_EXPIRY_INTERVAL_IN_SEC
        @entries_monitor.synchronize do
          Cache.entries.each_key do |key|
            if Time.now.to_i > Cache.entries.fetch(key).timeout
              Cache.entries.delete(key)
            end
          end
        end
      end
    end
  end
end