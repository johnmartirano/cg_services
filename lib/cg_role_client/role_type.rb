require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  # A role type groups together a named set of activities that an actor or group
  # may be associated with by virtue of a granted role.
  class RoleType
    include Aspect4r
    include ActiveModel::Validations
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :role_name, :target_type, :created_at, :updated_at

    validates_presence_of :role_name, :target_type
    validates_length_of :role_name, :target_type, :maximum=>255

    class << self

      around :all, :find, :find_by_role_name_and_target_type do |*args, &block|
        begin
          ensure_endpoint
          block.call(*args)
        rescue Exception => e
          puts e
          raise
        end
      end

      def all
        @endpoint.find_all_role_types
      end

      def find(id)
        @endpoint.find_role_type_by_id(id)
      end

      def find_by_role_name_and_target_type(role_name, target_type)
        @endpoint.find_role_type_by_role_name_and_target_type(role_name, target_type)
      end

      def method_missing(sym, *args, &block)
        find_by_role_name_and_target_type(sym.to_s, *args)
      end

    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def activities
      begin
        RoleType.ensure_endpoint
        RoleType.endpoint.find_role_type_activities_by_role_type_id(@id)
      rescue Exception => e
        puts e
        raise
      end
    end

  end

end
