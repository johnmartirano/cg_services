require 'cg_lookup_client'
require 'request_store'

module CgServiceClient

  # Generic base class for interacting with RESTFul service endpoints.
  class RestEndpoint
    include CgLookupClient::UriWithVersion

    REQUEST_TIMEOUT = 10000 # milliseconds

    attr_reader :name

    def initialize(name, uri, version)
      @name = name
      set_uri_and_version(uri, version)
      @cache = CgServiceClient::Cache.new
    end

    # Ping the service referenced by this endpoint.
    #
    # @return [Boolean] true if the service responded to the ping
    def ping
      begin
        self.run_request(uri_with_version + 'ping/?',
                       {:method => :get,
                        :headers => {"Accept" => "text/html"},
                        :timeout => RestEndpoint::REQUEST_TIMEOUT}
                      ) do |response|
                        response && response.body == "Success"
                      end
      rescue
        nil
      end
    end

    protected

    # Instrument for timing etc.  See initializer in cg_community.
    # May want to make these available in all apps.
    def instrument(hash, &block)
      ActiveSupport::Notifications.instrument('service_call.cgservice', hash, &block)
    end

    def run_request(request_url, request_options = {}, options = {}, &block)
      options = {:only_cache_200s => true}.merge(options)

      if cacheable_request?(request_options)
        key = rest_client_cache_key(request_url, request_options[:params])
        
        response = request_store_get(key) || shared_store_get(key)
        if response
          instrument(:url => request_url, :params => request_options[:params], :cached => true)
        else
          instrument(:url => request_url, :params => request_options[:params], :cached => false) do
            response = run_rest_client_request(request_url, request_options)
          end
          
          # any response to GET goes into the per-request store
          request_store_put(key, response)

          # only 'good' responses go into the shared cache
          if cacheable_response?(request_options, options, response)
            shared_store_put(key, response, request_options[:cache_timeout])
          end
        end
      else
        # any non-cacheable request (e.g. PUT, POST), clears out the
        # pre-request store under the assumption that, e.g., role
        # service roles have been modified
        request_store_clear!
        instrument(:url => request_url, :params => request_options[:params], :cached => :not_cacheable) do
          response = run_rest_client_request(request_url, request_options)
        end
      end

      if (200..299).include?(response.code)
        yield response
      elsif (400..499).include?(response.code)
        raise(CgServiceClient::Exceptions::ClientError.new(response.code, response.description),
              "Client error #{response.code}: #{response.body}.")
      elsif response.code >= 500
        raise(CgServiceClient::Exceptions::ServerError.new(response.code, response.description),
              "Server error #{response.code}: #{response.body}.")
      elsif response.code == 0
        # no http response
        raise(CgServiceClient::Exceptions::ConnectionError.new(response.code, response.description),
              response.description)
        #elsif response.timed_out?
        #  raise CgServiceClient::Exceptions::TimeoutError.new(response.code, response.curl_error_message), "Request for #{request_url} timed out."
      else
        raise(CgServiceClient::Exceptions::ConnectionError.new(response.code, response.body),
              "Request for #{request_url} failed.")
      end
    end

    def rest_client_cache_key(url, params = nil)
      if params
        Digest::SHA1.hexdigest(url + params.to_s)
      else
        Digest::SHA1.hexdigest(url)
      end
    end

    def cacheable_request?(request_options)
      [:get, :head].include?(request_options[:method])
    end

    # Just checks the status code is 2xx if options[:only_cache_200s]
    def good_to_cache?(response, options)
      options[:only_cache_200s] ? (200..299).include?(response.code) : true
    end

    def cacheable_response?(request_options, options, response)
      (request_options[:cache_timeout] &&
       cacheable_request?(request_options) &&
       good_to_cache?(response, options))
    end

    def request_store_get(key)
      (RequestStore.store[:cg_service_client] ||= {})[key]
    end

    def request_store_put(key, value)
      (RequestStore.store[:cg_service_client] ||= {})[key] = value
    end

    def request_store_clear!
      hash = RequestStore.store[:cg_service_client]
      hash && hash.clear
    end

    def shared_store_get(key)
      begin
        @cache.get(key)
      rescue => e
        # FIXME: this rescue should not be necessary...  Better would
        # be to use a logger to log a message perhaps?  This is here
        # just as a last resort.
        puts "ERROR: #{e} cache lookup failed for #{request_url}, #{request_options[:params]}"
        nil
      end
    end

    def shared_store_put(key, value, timeout)
      @cache.set(key, value, timeout)
    end

    def run_rest_client_request(request_url, request_options = {})
      request_options[:timeout] ||= REQUEST_TIMEOUT
      timeout = (request_options[:timeout] / 1000)
      params = request_options[:params]
      request_options[:headers].merge!({:params => request_options.delete(:params)}) if request_options[:params]
      request = RestClient::Request.new({:url => request_url,
                                          :method => request_options[:method],
                                          :headers => request_options[:headers],
                                          :payload => request_options[:body],
                                          :timeout => timeout})
      request.execute
    rescue RestClient::RequestTimeout => e
      raise CgServiceClient::Exceptions::TimeoutError.new(nil, nil), "Request for #{request_url} timed out."
    rescue Errno::ECONNREFUSED
      # FIXME: not needed if #with_endpoint is used in all service clients
      CgLookupClient::ENDPOINTS.refresh(self.class, name, version)
      raise
    end
  end
end
