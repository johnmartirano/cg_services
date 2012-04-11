#require 'typhoeus'

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

    def run_request(request_url, request_options = {}, options = {}, &block)
			if defined?(JRUBY_VERSION)
        run_rest_client_request(request_url, request_options, options, &block)
			else
			  request = Typhoeus::Request.new(request_url, request_options)
				run_typhoeus_request(request, options, &block)
			end
    end

    def rest_client_cache_key(url)
			Digest::SHA1.hexdigest(url)
    end

		def run_rest_client_request(request_url, request_options = {}, options = {}, &block)
			options = {:only_cache_200s => true}.merge(options)

      if request_options[:method] == :get
        response = @cache.get(rest_client_cache_key(request_url)) rescue nil
      end

      request_options[:timeout] ||= REQUEST_TIMEOUT
      timeout = (request_options[:timeout] / 1000)
      request_options[:headers].merge!({:params => request_options.delete(:params)}) if request_options[:params]
      request = RestClient::Request.new({:url => request_url,
                                         :method => request_options[:method],
                                         :headers => request_options[:headers],
                                         :payload => request_options[:body],
                                         :timeout => timeout})

      if response.nil?
        begin
          response = request.execute
        rescue RestClient::RequestTimeout => e
          raise CgServiceClient::Exceptions::TimeoutError.new(nil, nil), "Request for #{request_url} timed out."
        end
      end

      ret = nil
      if (response.code >= 200 && response.code < 300)
        if (request_options[:method] == :get && request_options[:cache_timeout] && cacheable?(response, options))
          @cache.set(rest_client_cache_key(request_url), response, request_options[:cache_timeout])
        end
        ret = yield response
      elsif response.code >= 400 && response.code < 500
        raise CgServiceClient::Exceptions::ClientError.new(response.code, response.description), "Client error #{response.code}: #{response.body}."
      elsif response.code >= 500
        raise CgServiceClient::Exceptions::ServerError.new(response.code, response.description), "Server error #{response.code}: #{response.body}."
      elsif response.code == 0
        # no http response
        raise CgServiceClient::Exceptions::ConnectionError.new(response.code, response.description), response.description
      #elsif response.timed_out?
      #  raise CgServiceClient::Exceptions::TimeoutError.new(response.code, response.curl_error_message), "Request for #{request_url} timed out."
      else
        raise CgServiceClient::Exceptions::ConnectionError.new(response.code, response.body), "Request for #{request_url} failed."
      end

			ret
		end

      # Returns the result of the block on success.
      # Options:
      #     :only_cache_200s Whether or not to only cache responses that return a 200
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

    def cacheable?(response, options)
      !options[:only_cache_200s] ||
          (options[:only_cache_200s] && response.code >= 200 && response.code < 300)
    end
  end

end
