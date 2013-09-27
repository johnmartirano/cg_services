require 'active_model'
require 'aspect4r'
require 'cg_role_client/rest_endpoint'
require 'cg_service_client'

module CgRoleClient

  # A role type groups together a named set of activities that an actor or group
  # may be associated with by virtue of a granted role.
  class RoleType
    include CgServiceClient::Base

    uses_service("Role", "1", CgRoleClient::RestEndpoint)

    serializable_attr_accessor :id, :role_name, :target_type, :created_at, :updated_at

    validates_presence_of :role_name, :target_type
    validates_length_of :role_name, :target_type, :maximum=>255

    class << self
      def all
        with_endpoint do |endpoint|
          endpoint.find_all_role_types
        end
      end

      def find(id)
        with_endpoint do |endpoint|
          endpoint.find_role_type_by_id(id)
        end
      end

      def find_by_role_name_and_target_type(role_name, target_type)
        with_endpoint do |endpoint|
          endpoint.find_role_type_by_role_name_and_target_type(role_name, target_type)
        end
      end

      def method_missing(sym, *args, &block)
        Rails.logger.warn "CgRoleClient::RoleType.role_type('target_type') is deprecated, use CgRoleClient::RoleType.get(:role_type, 'target_type')"
        Rails.logger.warn "Called by #{caller.first}"
        self.find(sym.to_s, *args)
      end

      def get(sym, *args)
        find_by_role_name_and_target_type(sym.to_s, *args)
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def activities
      with_endpoint do |endpoint|
        return @role_type_activities if defined? @role_type_activities
        @role_type_activities = endpoint.find_role_type_activities_by_role_type_id(@id)
      end
    end
  end
end
