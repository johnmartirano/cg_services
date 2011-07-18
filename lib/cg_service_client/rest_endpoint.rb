require 'typhoeus'

module CgServiceClient
  class RestEndpoint
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

    protected

    def run_synchronous_typhoeus_request(request)
      request.on_complete do |response|
        if response.success?
          yield
        elsif response.code >= 400 && response.code < 500
          raise CgServiceClient::Exceptions::ClientError.new(response.code, response.status_message), "Client error #{response.code}: #{response.body}."
        elsif response.code >= 500
          raise CgServiceClient::Exceptions::ServerError.new(response.code, response.status_message), "Server error #{response.code}: #{response.body}."
        elsif response.code == 0
          # no http response
          raise CgServiceClient::Exceptions::ConnectionError.new(response.curl_error_code, response.curl_error_message), response.curl_error_message
        elsif response.timed_out?
          raise CgServiceClient::Exceptions::TimeoutError.new(response.curl_error_code, response.curl_error_message), "Request for #{request_url} timed out."
        else
          raise CgServiceClient::Exceptions::ConnectionError.new(response.code, response.body), "Request for #{request_url} failed."
        end

      end
    end

    hydra = Typhoeus::Hydra.new
    hydra.queue(request)
    hydra.run
  end


end
end
