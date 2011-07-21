require 'cg_lookup_client'

module CgServiceClient
  module Serviceable
    ENDPOINT_FLUSH_INTERVAL_IN_SEC = 60

    attr_reader :endpoint

    def uses_service(service_name, service_version, endpoint_class)
      @service_name = service_name
      @service_version = service_version
      @endpoint_class = endpoint_class
      @endpoint = find_service_endpoint
    end

    def find_service_endpoint
      result = CgLookupClient::Entry.lookup(@service_name, @service_version)
      if result.nil? || result[:entry].nil?
        raise ServiceUnavailableError, "No #{name} services are available."
      else
        eval(@endpoint_class).new(result[:entry].uri, @service_version)
      end
    end

      # This thread periodically clears out the endpoint reference, thereby forcing it to be resolved again.
    Thread.new do
      loop do
        sleep ENDPOINT_FLUSH_INTERVAL_IN_SEC
        @endpoint = find_service_version
      end
    end

    class ServiceUnavailableError < StandardError;
    end
  end
end