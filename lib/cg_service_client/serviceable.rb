require 'cg_lookup_client'

module CgServiceClient
  module Serviceable
    @endpoint = nil

    attr_reader :endpoint

    def uses_service(service_name, service_version, endpoint_class)
      if @endpoint.nil?
        @endpoint = find_service_endpoint(service_name, service_version, endpoint_class)
      end
    end

    def find_service_endpoint(service_name, service_version, endpoint_class)
      result = CgLookupClient::Entry.lookup(service_name, service_version)
      if result.nil? || result[:entry].nil?
        raise ServiceUnavailableError, "No #{name} services are available."
      else
        eval(endpoint_class).new(result[:entry].uri, service_version)
      end
    end

    class ServiceUnavailableError < StandardError;
    end
  end
end