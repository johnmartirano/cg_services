require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Role
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :group_id, :target_id, :role_type_id, :created_at, :updated_at

    validates_presence_of :group_id, :target_id, :role_type_id

    class << self
      include Aspect4r

      around :grant, :aggregate_role do |*args, &block |
        begin
          ensure_endpoint
          block.call(*args)
        rescue Exception => e
          puts e
          raise
        end
      end

      # Grant a new role for an actor or group on a target. Target
      # must be an entity with an ID.
      def grant(role_type, actor_or_group, target)
        group = group_for(actor_or_group)
        role = Role.new({:role_type_id => role_type.id,
                         :group_id => group.id,
                         :target_id => target.id })
        @endpoint.create_role(role)
      end

      def aggregate_role(actor_or_group, target)
        group = group_for(actor_or_group)
        roles = @endpoint.find_group_roles_on_target(group.id, target.class, target.id)
        CgRoleClient::AggregateRole.new(roles)
      end

      def group_for(actor_or_group)
        group = actor_or_group
        if actor_or_group.kind_of? CgRoleClient::Actor
          group = @endpoint.find_singleton_group_by_actor_id(actor_or_group.id)
        end
      end

      private :group_for
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def role_type
      RoleType.find(@role_type_id)
    end
  end

end
