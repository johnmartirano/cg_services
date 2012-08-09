require 'cg_lookup_client'

module CgServiceClient
  # This mixin provides convenience methods for instantiating and renewing service endpoints.
  # To use this mixin, include the following at the beginning of your class:
  # extend CgServiceClient::Serviceable
  # Then, call uses_service to set the initialization variables. endpoint_class
  # should be a subclass of CgServiceClient::RestEndpoint.
  # Finally, at the beginning of any method that makes calls on the endpoint, make sure
  # to call ensure_endpoint.
  module Serviceable
    ENDPOINT_FLUSH_INTERVAL_IN_SEC = 60

    attr_reader :endpoint

    # Looks up the given service and instantiates the given RestEndpoint.
    # Makes available a class instance variable, @endpoint, that can be
    # used to interact with the endpoint. The endpoint will be periodically
    # refreshed.
    def uses_service(service_name, service_version, endpoint_class)
      @service_name = service_name
      @service_version = service_version
      @endpoint_class = endpoint_class
    end

    def find_service_endpoint
=begin
      result = CgLookupClient::Entry.lookup(@service_name, @service_version)
      if result.nil? || result[:entry].nil?
        raise ServiceUnavailableError, "No #{@service_name} services are available."
      else
        eval(@endpoint_class).new(result[:entry].uri, @service_version)
      end
=end
      results = CgLookupClient::Entry.lookup(@service_name, @service_version)
      if results.nil? || result.compact.blank?
        raise ServiceUnavailableError, "No #{@service_name} services are available."
      end
      to_ping = results.compact.map do |result|
        eval(@endpoint_class).new(result[:entry].uri, @service_version)
      end
      to_ping.select {|endpoint| endpoint.ping }.first #async pings required?
    end

    def ensure_endpoint
      if @endpoint == nil # || @endpoint.ping failed
        @endpoint = find_service_endpoint
      end
    end

      # This thread periodically refreshes the endpoint
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
