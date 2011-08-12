require 'active_model'
require 'cg_service_client'

module CgRoleClient

  class Activity
    include ActiveModel::Validations
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    class << self
      def endpoint
        ensure_endpoint
        @endpoint
      end

      def method_missing(sym, *args, &block)
        begin
          endpoint.find_activity_by_code(sym.to_s)
        rescue Exception => e
          puts e
          raise
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def eql?(object)
      if object.equal?(self)
        return true
      elsif !self.class.equal?(object.class)
        return false
      end

      object.code.eql? code
    end

    def hash
      code.hash
    end

  end

end
