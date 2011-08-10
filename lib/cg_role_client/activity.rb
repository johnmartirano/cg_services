require 'active_model'
require 'cg_service_client'
require 'cg_service_client/rest_endpoint'
require 'cg_role_client/rest_endpoint'

module CgRoleClient

  class Activity
    include ActiveModel::Validations
    extend CgServiceClient::Serviceable
    include CgServiceClient::Serializable

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    class << self
      def endpoint
        ensure_endpoint
        @endpoint
      end

      def method_missing(sym, *args, &block)
        endpoint.find_activity_by_code(sym.to_s)
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end
