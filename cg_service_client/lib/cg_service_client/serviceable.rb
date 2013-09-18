require 'cg_lookup_client'

module CgServiceClient
  class ServiceUnavailableError < StandardError; end

  # This mixin provides convenience methods for instantiating and renewing service endpoints.
  # To use this mixin, include the following at the beginning of your class:
  # extend CgServiceClient::Serviceable
  # Then, call uses_service to set the initialization variables. endpoint_class
  # should be a subclass of CgServiceClient::RestEndpoint.
  module Serviceable
    ENDPOINT_FLUSH_INTERVAL_IN_SEC = 60

    # Define the service that this class uses.  Calls to the class
    # method {.endpoint} will lookup the endpoint in the global
    # CgLookupClient::ENDPOINTS, which handles caching, refreshing,
    # etc.
    def uses_service(service_name, service_version, endpoint_class)
      @service_name = service_name
      @service_version = service_version
      @endpoint_class = endpoint_class
    end

    # Forward to CgLookupClient::CachingEndpointSet#with_endpoint
    # using the globally shared CgLookupClient::ENDPOINTS.  The block
    # may be invoked two or more times if the endpoint fails with
    # ECONNREFUSED.
    #
    # See CP-1912, CP-2758
    #
    # @see CgLookupClient::CachingEndpointSet#with_endpoint
    # @raises ServiceUnavailableError (rather than CgLookupClient::NotFoundError)
    def with_endpoint(opts = {}, &block)
      CgLookupClient::ENDPOINTS.with_endpoint(@endpoint_class,
                                              @service_name,
                                              @service_version,
                                              opts,
                                              &block)
    rescue CgLookupClient::NotFoundError => e
      raise ServiceUnavailableError, e.message
    end

    # Get the endpoint, possibly looking it up from a lookup service,
    # according to the configuration in {#uses_service}.
    #
    # See CP-1912, CP-2758
    def endpoint
      CgLookupClient::ENDPOINTS.get(@endpoint_class, @service_name, @service_version)
    rescue CgLookupClient::NotFoundError => e
      raise ServiceUnavailableError, e.message
    end
  end
end
