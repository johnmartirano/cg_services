require 'logger'
require 'monitor'
require 'set'

module CgLookupClient
  class NotFoundError < StandardError; end

  # A caching wrapper around multiple CgLookupClient::RestEndpoint
  # objects.
  #
  # Services are looked up from multiple endpoints, pinged to check if
  # they are working, and then added to a cache.  Subsequent calls to
  # #get will return the cached endpoints.
  #
  # Periodically, cached lookups are refreshed in a background thread.
  #
  # Users of this EndpointSet should call #get to get endpoints to
  # services.  If an endpoint is determined to be down, #evict! should
  # be called as soon as possible to prevent other threads from being
  # handed that same broken endpoint.  The periodic refresh will
  # restore the endpoint should it ever become available again.
  class CachingEndpointSet
    include MonitorMixin

    SUPPORTED_ENDPOINT_VERSIONS = %w( 1 )

    # objects of this type are stored in the cache; value is an array
    # of endpoints
    Data = Struct.new(:value, :updated_at)

    # object used as cache key
    Key = Struct.new(:endpoint_class, :type, :version)

    attr_reader :refresh_period

    # Logging on Ruby is terrible.  Please use this non-threadsafe
    # accessor to set a logger; otherwise logs go to stdout.
    attr_accessor :logger

    # @param [Hash] opts
    # @option opts [Boolean] :auto_refresh (default true)
    # @option opts [Integer] :refresh_period refresh period in seconds (default 1 minute)
    def initialize(opts = {})
      super()                   # required to initialize MonitorMixin

      @endpoints = Set.new
      @cache = {}
      @logger = Logger.new(STDOUT)

      @auto_refresh = opts[:auto_refresh] || true
      @refresh_period = opts[:refresh_period] || 60 # 1 minute
    end

    def auto_refresh?
      @auto_refresh
    end

    # Ugh. Ruby 1.8 has Array#choice.  Ruby 1.9 has Array#sample.
    # Remove this after MUPP merge (move to 1.9).
    if RUBY_VERSION.start_with?('1.8')
      def sample(ary)
        ary.choice
      end
    else
      def sample(ary)
        ary.sample
      end
    end

    # @return [Integer] the current number of rest endpoints
    def size
      synchronize { @endpoints.size }
    end

    # Add an endpoint to the set of endpoints that will be polled
    # during lookups.
    #
    # @param [CgLookupClient::RestEndpoint] endpoint
    def add(endpoint)
      unless SUPPORTED_ENDPOINT_VERSIONS.include?(endpoint.version)
        raise(UnsupportedEndpointVersionError,
              "Version #{endpoint.version} endpoints are not supported.")
      end

      synchronize { @endpoints.add endpoint }
    end

    # Choose at random one endpoint from the set of matching
    # endpoints.  If none are cached, a lookup will be performed
    # against all lookup endpoints.
    #
    # @param [Class] endpoint_class the class of endpoint to return
    # @param [String] type the type or name of endpoint to lookup
    # @param [String] version the version of endpoing to lookup
    def get(endpoint_class, type, version)
      get_by_key(make_key(endpoint_class, type, version))
    end

    def get_by_key(key)
      synchronize { sample(cache_get(key, &method(:lookup))) }
    end

    # Get an endpoint using #get and yield it to the block.  If an
    # Errno::ECONNREFUSED exception is raised, the endpoint is
    # evicted, and the block is tried again up to a configurable
    # number of times (including the first try).
    #
    # @param [Class] endpoint_class the class of endpoint to return
    # @param [String] type the type or name of endpoint to lookup
    # @param [String] version the version of endpoint to lookup
    # @param [Hash] opts
    # @option opts [Integer] :tries number of allowed tries (default 2)
    def with_endpoint(endpoint_class, type, version, opts = {})
      remain = opts[:tries] || 2

      key = make_key(endpoint_class, type, version)

      endpoint = nil
      begin
        remain -= 1
        endpoint = get_by_key(key)
        yield(endpoint)
      rescue Errno::ECONNREFUSED
        if endpoint
          evict!(endpoint)
          endpoint = nil
        end
        retry if remain > 0
        raise
      end
    end

    # Remove an endpoint from the cache so it will no longer be handed
    # out by #get.  A periodic refresh may restore the endpoint if it
    # responds to ping.
    def evict!(bad_endpoint)
      synchronize do
        key = make_key(bad_endpoint.class, bad_endpoint.name, bad_endpoint.version)
        if endpoints = cache_get(key)
          endpoints.delete(bad_endpoint)
        end
      end
    end

    # Force a lookup, refreshing any entries stored in the cache.
    #
    # @param [Class] endpoint_class the class of endpoint to return
    # @param [String] type the type or name of endpoint to lookup
    # @param [String] version the version of endpoint to lookup
    #
    # @deprecated Use {#with_endpoint} or {#evict!} to handle bad endpoints
    def refresh(endpoint_class, type, version)
      cache_put(make_key(endpoint_class, type, version),
                lookup(endpoint_class, type, version))
      nil
    end

    private

    # Make a cache key.
    #
    # @param [String] type
    # @param [String] version
    def make_key(endpoint_class, type, version)
      Key.new(endpoint_class, type, version).freeze
    end

    # Get the value corresponding to +key+ from the cache.  If it is
    # older than the refresh age, a refresh background task will be
    # kicked off.
    #
    # If the value is not found, the block will be yielded to with
    # [+endpoint_class+, +type+, +version+] args, and the result
    # stored in the cache (while continuing to hold the lock; so other
    # threads will block until the initial lookup completes),
    # otherwise nil is returned.
    #
    # @return [Object] a value from cache, or if not found the value
    # of a the given block or nil
    def cache_get(key)
      synchronize do
        data = @cache[key]
        if !data.nil? && !data.value.empty?
          # kick off a refresh, maybe
          lookup_in_background(key) if (auto_refresh? && stale?(data))
          
          data.value
        elsif block_given?
          data = cache_put(key, yield(key.endpoint_class, key.type, key.version))
          data.value
        end
      end
    end

    # Store +value+ in the cache at +key+.
    #
    # @param [Object] key
    # @param [Array] value
    # @param [Time] updated_at time to use as the +updated_at+
    def cache_put(key, value, updated_at = Time.now)
      synchronize do
        @cache[key] = Data.new(value, updated_at)
      end
    end

    # Test if the Data object +data+ is stale (older than some age).
    #
    # @param [Data] data
    # @param [Time] now time from which to measure the age, based on data.updated_at
    def stale?(data, now = Time.now)
      (now - data.updated_at) > refresh_period
    end

    # TODO: ensure at most only one per key is running
    def lookup_in_background(key)
      Thread.new do
        begin
          alive = lookup(key.endpoint_class, key.type, key.version)
          cache_put(key, alive)
        rescue => e
          logger.error { "error looking up #{key.type}, #{key.version}: #{e}" }
        end
      end
    end

    # Perform a lookup against all lookup endpoints for endpoints
    # matching +type+ and +version+.  Instantiates them as
    # +endpoint_class+, ensures #ping succeeds, and returns an array
    # of live endpoints.
    #
    # @raise [NotFoundError] if no matching endpoints are found or none responded to ping
    def lookup(endpoint_class, type, version)
      # Important to not hold the lock the entire time so that looking
      # up in a background thread doesn't hold up the show.
      endpoints = synchronize { @endpoints.to_a }
      if endpoints.empty?
        msg = 'no endpoints have been added'
        raise CgLookupClient::NoEndpointConfiguredError, msg
      end

      results = endpoints.
        reduce([]) {|all, endpoint| all.concat(endpoint.lookup(type)) }.
        map{|e| e[:entry] }.
        compact.
        select{|e| e.version == version }
      
      if results.empty?
        raise NotFoundError, "No #{type} services available in #{endpoints.join(',')}"
      end

      alive = results.
        map{|e| endpoint_class.new(type, e.uri, e.version) }.
        select{|e| e.ping }
      
      if alive.empty?
        found = results.map(&:uri).join(',')
        raise NotFoundError, "No #{type} services responded to ping (#{found})"
      end

      alive
    end
  end
end
