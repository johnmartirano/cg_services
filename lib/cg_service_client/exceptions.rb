module CgServiceClient
  module Exceptions
    class HttpError < StandardError
      attr_writer :message
      attr_reader :http_code, :status_message

      def initialize(http_code, status_message)
        @http_code = http_code
        @status_message = status_message
      end
    end
      # 4xx level errors
    class ClientError < HttpError
      def initialize(http_code, status_message)
        super http_code, status_message
      end
    end
      # 5xx level errors
    class ServerError < HttpError
      def initialize(http_code, status_message)
        super http_code, status_message
      end
    end

    class ConnectionError < StandardError
      attr_writer :message
      attr_reader :error_code, :error_message

      def initialize(error_code, error_message)
        @error_code = error_code
        @error_message = error_message
      end
    end
    class TimeoutError < ConnectionError
      def initialize(error_code, error_message)
        super(error_code, error_message)
      end
    end
  end
end