require 'typhoeus'

module CgServiceClient
  # Generic base class for interacting with RESTFul service endpoints.
  class RestEndpoint
    REQUEST_TIMEOUT = 10000 # milliseconds

    attr_reader :uri, :version

    def initialize(uri, version)
      @uri = uri
        # ensure trailing slash on uri
      @uri << '/' if @uri[-1].chr != '/'
        # to_s in case a number is passed in
      @version = version.to_s
      @cache = CgServiceClient::Cache.new
    end

    def uri_with_version
      @uri + 'v' + @version + "/"
    end

    def eql?(object)
      if object.equal?(self)
        return true
      elsif !self.class.equal?(object.class)
        return false
      end

      object.uri_with_version.eql?(uri_with_version)
    end

    def hash
      uri_with_version.hash
    end

    protected

      # Returns the result of the block on success.
      # Options:
      #     :cache_404_responses Whether or not to cache responses that return a 404
    def run_typhoeus_request(request, options = {})
      options = {:only_cache_200s => true}.merge(options)

      ret = nil

      request.on_complete do |response|
        if response.success?
          ret = yield response
        elsif response.code >= 400 && response.code < 500
          raise CgServiceClient::Exceptions::ClientError.new(response.code, response.status_message), "Client error #{response.code}: #{response.body}."
        elsif response.code >= 500
          raise CgServiceClient::Exceptions::ServerError.new(response.code, response.status_message), "Server error #{response.code}: #{response.body}."
        elsif response.code == 0
          # no http response
          raise CgServiceClient::Exceptions::ConnectionError.new(response.curl_return_code, response.curl_error_message), response.curl_error_message
        elsif response.timed_out?
          raise CgServiceClient::Exceptions::TimeoutError.new(response.curl_return_code, response.curl_error_message), "Request for #{request_url} timed out."
        else
          raise CgServiceClient::Exceptions::ConnectionError.new(response.code, response.body), "Request for #{request_url} failed."
        end

      end

      hydra = Typhoeus::Hydra.new

      hydra.cache_setter do |request|
        if(request.cache_timeout && cacheable?(request, options))
          @cache.set(request.cache_key, request.response, request.cache_timeout)
        end
      end

      hydra.cache_getter do |request|
        @cache.get(request.cache_key) rescue nil
      end

      hydra.queue(request)
      hydra.run

      ret
    end

    def cacheable?(request, options)
      !options[:only_cache_200s] ||
          (options[:only_cache_200s] && request.response.code >= 200 && request.response.code < 300)
    end
  end

end
