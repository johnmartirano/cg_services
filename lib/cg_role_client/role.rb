require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient
  # A role represents a set of permissions for an actor or group
  # on a particular target.
  class Role
    include CgServiceClient::Base

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :group_id, :target_id, :role_type_id, :created_at, :updated_at

    validates_presence_of :group_id, :target_id, :role_type_id

    class << self
      # Grant a new role for an actor or group on a target. Target
      # must be an entity with an ID.
      def grant(role_type, actor_or_group, target)
        try_service_call do
          group = group_for(actor_or_group)
          role = Role.new({:role_type_id => role_type.id,
                            :group_id => group.id,
                            :target_id => target.id})
          endpoint.create_role(role)
        end
      end

      # Get the aggregate role for an actor or group on a target.  See
      # CgRoleClient::AggregateRole
      def aggregate_role(actor_or_group, target)
        try_service_call do
          if target.class == Hash
            target = target
          else
            target = {:class => target.class, :id => target.id}
          end
          begin
            if actor_or_group.kind_of? CgRoleClient::Actor
              roles = endpoint.find_actor_roles_on_target(actor_or_group.id, target[:class], target[:id])
            else
              roles = endpoint.find_group_roles_on_target(actor_or_group.id, target[:class], target[:id])
            end
          rescue => e
            if e.kind_of?(CgServiceClient::Exceptions::ClientError) && e.http_code == 404
              roles = []
            else
              raise
            end
          end
          CgRoleClient::AggregateRole.new(roles)
        end
      end

      def group_for(actor_or_group)
        group = actor_or_group
        if actor_or_group.kind_of? CgRoleClient::Actor
          group = endpoint.find_singleton_group_by_actor_id(actor_or_group.id)
        end
        group
      end

      private :group_for
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def revoke
      try_service_call do
        endpoint.remove_role(@id)
      end
    end

    def role_type
      RoleType.find(@role_type_id)
    end
  end
end
