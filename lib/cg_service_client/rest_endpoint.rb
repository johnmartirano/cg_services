require 'typhoeus'

module CgServiceClient
  # Generic base class for interacting with RESTFul service endpoints.
  class RestEndpoint
    include Exceptions

    REQUEST_TIMEOUT = 10000 # milliseconds

    attr_reader :uri, :version, :hydra

    def initialize(uri, version)
      @uri = uri
        # ensure trailing slash on uri
      @uri << '/' if @uri[-1].chr != '/'
        # to_s in case a number is passed in
      @version = version.to_s
      @cache = Cache.new

      @hydra = Typhoeus::Hydra.new

      # Note: previously, a (default on) option to
      # #run_typhoeus_request determined whether to only cache 200
      # level responses.  But since I'm now re-using the same Hydra
      # (rather than creating a new one for each request), I'm just
      # hardcoding this to always only cache 200 level responses.
      # (There was no code that requested anything but the default
      # behavior anyway.)
      @hydra.cache_setter do |req|
        if req.response.code >= 200 && req.response.code < 300
          @cache.set(req.cache_key, req.response, req.cache_timeout)
        end
      end

      @hydra.cache_getter do |req|
        @cache.get(req.cache_key) rescue nil
      end
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

    # @returns [Object] the result of the block
    def run_typhoeus_request(request)
      request.on_complete do |resp|
        if resp.success?
          yield resp
        elsif resp.code >= 400 && resp.code < 500
          raise(ClientError.new(resp.code, resp.status_message),
                "Client error #{resp.code}: #{resp.body}.")
        elsif resp.code >= 500
          raise(ServerError.new(resp.code, resp.status_message),
                "Server error #{resp.code}: #{resp.body}.")
        elsif resp.code == 0
          # no http resp
          raise(ConnectionError.new(resp.curl_return_code, resp.curl_error_message),
                resp.curl_error_message)
        elsif resp.timed_out?
          raise(TimeoutError.new(resp.curl_return_code, resp.curl_error_message),
                "Request for #{request_url} timed out.")
        else
          raise(ConnectionError.new(resp.code, resp.body),
                "Request for #{request_url} failed.")
        end
      end

      hydra.queue(request)
      hydra.run
      
      request.handled_response
    end
  end

end
