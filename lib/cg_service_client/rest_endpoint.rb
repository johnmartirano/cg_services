require 'cg_lookup_client'

module CgServiceClient

  class ServiceUnavailableError < StandardError;
  end

  # Generic base class for interacting with RESTFul service endpoints.
  class RestEndpoint

    class << self
      #class instance vars to govern the refresh process
      def endpoints
        @endpoints ||= Hash.new do |h,k|
          h[k] = Hash.new {|h,k| h[k] = [] }
        end
      end

      def refreshed_times
        @refreshed_times ||= Hash.new { |h,k| h[k] = {} }
      end

      # a random selection from last known good endpoints of the given type
      # refresh after two minutes or if there are no known good endpoints
      def get(service_name, service_version, endpoint_class)
        if endpoints[service_name][service_version].blank? ||
           (refreshed_times[service_name][service_version] &&
           Time.now - refreshed_times[service_name][service_version] > 2.minutes)

          self.refresh(service_name, service_version, endpoint_class)
        end
        endpoints[service_name][service_version].sample
      end
      
      #get the current good endpoints from lookup service
      #could optimize by refreshing all endpoint types when we notice any type go down,
      #since there is a uri per node/service and all the services on a node are likely down
      def refresh(service_name, service_version, endpoint_class)
        if !@refreshing &&
           (refreshed_times[service_name][service_version].nil? ||
           Time.now - refreshed_times[service_name][service_version] > 5.seconds)

          do_refresh(service_name, service_version, endpoint_class)
        end
      end

      # get the lookup table entries and ping them, store responsive ones
      def do_refresh(service_name, service_version, endpoint_class)
        begin
          @refreshing = true
          results = CgLookupClient::Entry.lookup(service_name, service_version)
          if results.nil? || results.compact.blank?
            raise ServiceUnavailableError, "No #{service_name} services are available."
          end
          to_ping = results.compact.map do |result|
            endpoint_class.constantize.new(service_name, result[:entry].uri, service_version)
          end
          live_endpoints = to_ping.select {|endpoint| endpoint.ping }
          if live_endpoints.blank?
            raise ServiceUnavailableError, "No #{service_name} services are available."
          else
            endpoints[service_name][service_version] = live_endpoints
            refreshed_times[service_name][service_version] = Time.now
          end
        ensure
          @refreshing = false
        end
      end

    end

    REQUEST_TIMEOUT = 10000 # milliseconds

    attr_reader :name, :uri, :version

    def initialize(name, uri, version)
      @name = name
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

    def refresh
      CgServiceClient::RestEndpoint.refresh(@name, @version, self.class.to_s)
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

      #refreshed_count = 0
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
        rescue Errno::ECONNREFUSED => e
          #refreshed_count += 1
          refresh
          #once logger is defined for the services
          #logger.error "\n\n\n\n\n\n>>>>>>>>>> #{@name} service refused connection #{refreshed_count} time#{refreshed_count > 1 ? 's' : ''}"
          #only retry an arbitrary number of times to protect against infinite loop.
          #retry if refreshed_count <= 2
          #refresh raised an error if it could not produce a good endpoint,
          #so should only get here if the next endpoint it found went down between the ping and our retried request
          raise
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
