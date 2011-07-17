module CgServiceClient
  class RequestError < StandardError; end
  class TimeoutError < RequestError; end

  class ServerError < RequestError
    attr_writer   :message
    attr_reader   :http_code, :http_body

    def initialize(http_code,http_body)
      @http_code = http_code
      @http_body = http_body
    end
  end
end