require 'cg_service_client/logger'

module CgServiceClient
  module ServiceCall
    include CgServiceClient::Logger

    # Tries the block, which should be a service call, and retries
    # once if the call failed with a 'connection refused' or 'service
    # unavailable' error.
    def try_service_call
      begin
        begin
          yield
        rescue Errno::ECONNREFUSED, CgServiceClient::ServiceUnavailableError
          yield
        end
      rescue Exception => e
        logger.error e
        logger.error "    " + e.backtrace.join("\n    ")
        raise
      end
    end
  end
end
