require 'exceptions'
require 'active_support'
require 'typhoeus'

module CgServiceClient
  module ResponseHandlers
    def handle_typhoeus_response(response, request_url)
      if response.success?
        yield
      elsif response.code >= 400 && response.code < 500
        raise CgServiceClient::Exceptions::ClientError.new(response.code, response.status_message), "Client error " + response.code + ": " + response.body
      elsif response.code >= 500
        raise CgServiceClient::Exceptions::ServerError.new(response.code, response.status_message), "Server error " + response.code + ": " + response.body
      elsif response.code == 0
        # no http response
        raise CgServiceClient::Exceptions::ConnectionError.new(response.curl_error_code, response.curl_error_message), response.curl_error_message
      elsif response.timed_out?
        raise CgServiceClient::Exceptions::TimeoutError.new(response.curl_error_code, response.curl_error_message), "Request for " + request_url + " timed out."
      else
        raise CgServiceClient::Exceptions::ConnectionError.new(response.code, response.body), "Request for " + request_url + " failed."
      end
    end
  end
end