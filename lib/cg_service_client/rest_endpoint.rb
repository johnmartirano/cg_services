require 'typhoeus'

module CgServiceClient
  # Generic base class for interacting with RESTFul service endpoints.
  class RestEndpoint
    REQEUST_TIMEOUT = 5000 # milliseconds

    attr_reader :uri, :version

    def initialize(uri, version)
      @uri = uri
        # ensure trailing slash on uri
      @uri << '/' if @uri[-1].chr != '/'
        # to_s in case a number is passed in
      @version = version.to_s
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
    def run_typhoeus_request(request)
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
      hydra.queue(request)
      hydra.run

      ret
    end
  end

end
