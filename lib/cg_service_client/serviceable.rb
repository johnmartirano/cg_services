require 'cg_lookup_client'

module CgServiceClient
  # This mixin provides convenience methods for instantiating and renewing service endpoints.
  # To use this mixin, include the following at the beginning of your class:
  # extend CgServiceClient::Serviceable
  # Then, in the initializer, call YourClientClassName.use_service
  module Serviceable
    ENDPOINT_FLUSH_INTERVAL_IN_SEC = 60

    attr_reader :endpoint

    # Looks up the given service and instantiates the given RestEndpoint.
    # Makes available a class instance variable, @endpoint, that can be
    # used to interact with the endpoint. The endpoint will be periodically
    # refreshed.
    def use_service(service_name, service_version, endpoint_class)
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

      # This thread periodically refreshes the endpoint.
    Thread.new do
      loop do
        sleep ENDPOINT_FLUSH_INTERVAL_IN_SEC
        @endpoint = find_service_endpoint
      end
    end

    class ServiceUnavailableError < StandardError;
    end
  end
end