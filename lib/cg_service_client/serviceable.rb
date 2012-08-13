require 'cg_lookup_client'

module CgServiceClient
  # This mixin provides convenience methods for instantiating and renewing service endpoints.
  # To use this mixin, include the following at the beginning of your class:
  # extend CgServiceClient::Serviceable
  # Then, call uses_service to set the initialization variables. endpoint_class
  # should be a subclass of CgServiceClient::RestEndpoint.
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

    # CP-1912  CgServiceClient::RestEndpoint manages the relationship with lookup client,
    # and maintains a pool of endpoints for all the services on all the node agents
    # this way when any class notices a bad endpoint it can be refreshed for all classes
    def endpoint
      ep = CgServiceClient::RestEndpoint.get(@service_name, @service_version, @endpoint_class)
      if ep.nil?
        raise CgServiceClient::ServiceUnavailableError
      else
        ep
      end
    end

  end
end
