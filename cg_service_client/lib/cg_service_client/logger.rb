module CgServiceClient
  # Mixin to provide a logger object that logs to the Rails logger if
  # available or falls back to logging to stdout at DEBUG level.
  module Logger
    def logger
      if defined?(::Rails) && ::Rails.logger
        ::Rails.logger
      elsif defined(@logger)
        @logger
      else
        require 'logger'
        @logger = ::Logger.new($stdout)
        @logger.level = ::Logger::DEBUG
        @logger.warn '::Rails is not defined; logging to stdout'
        @logger
      end
    end
  end
end
