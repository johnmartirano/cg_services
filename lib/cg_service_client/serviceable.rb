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

    # CgServiceClient::RestEndpoint manages the relationship with lookup client,
    # and maintains a pool of endpoints for all the services on all the node agents
    # this way when any class notices a bad endpoint it can be refreshed for all classes
    def ensure_endpoint
      @endpoint = CgServiceClient::RestEndpoint.get(@service_name, @service_version, @endpoint_class)
    end

    class ServiceUnavailableError < StandardError;
    end

  end
end
