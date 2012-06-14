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
      run_rest_client_request(request_url, request_options, options, &block)
    end

    def rest_client_cache_key(url, params = nil)
      if params
        Digest::SHA1.hexdigest(url + params.to_s)
      else
        Digest::SHA1.hexdigest(url)
      end
    end

    def run_rest_client_request(request_url, request_options = {}, options = {}, &block)
      options = {:only_cache_200s => true}.merge(options)
      
      if request_options[:method] == :get
        response = begin
                     @cache.get(rest_client_cache_key(request_url, request_options[:params]))
                   rescue => e
                     # FIXME: this rescue should not be necessary...
                     # Better would be to use a logger to log a
                     # message perhaps?  This is here just as a last
                     # resort.
                     puts "ERROR: #{e} cache lookup failed for #{request_url}, #{request_options[:params]}"
                     nil
                   end
      end

      if response.nil?
        begin
          request_options[:timeout] ||= REQUEST_TIMEOUT
          timeout = (request_options[:timeout] / 1000)
          params = request_options[:params]
          request_options[:headers].merge!({:params => request_options.delete(:params)}) if request_options[:params]
          request = RestClient::Request.new({:url => request_url,
                                             :method => request_options[:method],
                                             :headers => request_options[:headers],
                                             :payload => request_options[:body],
                                             :timeout => timeout})
          response = request.execute
          if (response.code >= 200 && response.code < 300 && request_options[:method] == :get && request_options[:cache_timeout] && cacheable?(response, options))
            @cache.set(rest_client_cache_key(request_url, params), response, request_options[:cache_timeout])
          end
        rescue RestClient::RequestTimeout => e
          raise CgServiceClient::Exceptions::TimeoutError.new(nil, nil), "Request for #{request_url} timed out."
        end
      end

      ret = nil
      if (response.code >= 200 && response.code < 300)
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
    
    def cacheable?(response, options)
      !options[:only_cache_200s] ||
          (options[:only_cache_200s] && response.code >= 200 && response.code < 300)
    end
  end

end
