require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient
  # A role represents a set of permissions for an actor or group
  # on a particular target.
  class Role
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :group_id, :target_id, :role_type_id, :created_at, :updated_at

    validates_presence_of :group_id, :target_id, :role_type_id

    class << self
      include Aspect4r

      around :grant, :aggregate_role do |*args, &block |
        begin
          block.call(*args)
        rescue Errno::ECONNREFUSED => e
          begin #try again after refreshing, once only
            block.call(*args)
          rescue Exception => e
            puts e
            raise
          end
        rescue Exception => e
          puts e
          raise
        end
      end

        # Grant a new role for an actor or group on a target. Target
        # must be an entity with an ID.
      def grant(role_type, actor_or_group, target)
        if actor_or_group.is_a? CgRoleClient::Group
          role = Role.new({:role_type_id => role_type.id,
                           :group_id => actor_or_group.id,
                           :target_id => target.id})
          endpoint.create_role(role)
        else
          raise "TypeError: grant no longer accepts an actor as the parameter" if actor_or_group.is_a? CgRoleClient::Actor
          role = Role.new({:role_type_id => role_type.id,
                           :target_id => target.id})
          endpoint.create_actor_role(role, actor_or_group)
        end
      end

      # Get the aggregate role for an acting_entity on a target.
      # See CgRoleClient::AggregateRole
      def aggregate_role(acting_entity, target)
        raise "TypeError: aggregate_role no longer accepts an actor as the parameter: #{Kernel.caller(0)}" if acting_entity.is_a? CgRoleClient::Actor

        if target.class == Hash
          target = target
        else
          target = {:class => target.class, :id => target.id}
        end
        begin
            roles = endpoint.find_actor_roles_on_target(acting_entity, target[:class], target[:id])
        rescue => e
          if e.kind_of?(CgServiceClient::Exceptions::ClientError) && e.http_code == 404
            roles = []
          else
            raise
          end
        end
        CgRoleClient::AggregateRole.new(roles)
      end

      # Get the aggregate role for a group on a target.
      # See CgRoleClient::AggregateRole
      def aggregate_role_group(group, target)
        if target.class == Hash
          target = target
        else
          target = {:class => target.class, :id => target.id}
        end
        begin
          roles = endpoint.find_group_roles_on_target(group.id, target[:class], target[:id])
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

    def initialize(attributes = {})
      self.attributes = attributes
    end

    around :revoke do |*args, &block |
      begin
        block.call(*args)
      rescue Errno::ECONNREFUSED => e
        begin #try again after refreshing, once only
          block.call(*args)
        rescue Exception => e
          puts e
          raise
        end
      rescue Exception => e
        puts e
        puts e.backtrace.join("\n")
        raise e
      end
    end

    def revoke
      Role.endpoint.remove_role(@id)
    end

    def role_type
      RoleType.find(@role_type_id)
    end
  end

end
