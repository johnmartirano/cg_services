require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient
  # Actors are granted roles on target objects. It is a polymorphic type which
  # will usually represent CgUser::User but we may use other types as actors
  # in the future.
  class Actor
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :actor_id, :actor_type, :singleton_group_id, :created_at, :updated_at

    validates_presence_of :actor_id, :actor_type

    class << self
      include Aspect4r

      around :create, :find_by_actor_type_and_actor_id, :find_with_roles_on_target do | *args, &block |
        begin
          ensure_endpoint
          block.call(*args)
        rescue Exception => e
          puts e
          raise
        end
      end

      def create(attributes = {})
        actor = CgRoleClient::Actor.new(attributes)
        if !actor.valid? || !actor.id.nil?
          return false
        end
        @endpoint.create_actor(actor)
      end

      def find_by_actor_type_and_actor_id(actor_type, actor_id)
        @endpoint.find_actor_by_actor_type_and_actor_id(actor_type,actor_id)
      end

      def find_with_roles_on_target(target_id, target_type)
        @endpoint.find_with_roles_on_target(target_id, target_type)
      end

      def find_with_roles_on_target_with_activity(target, activity)
        actors = self.find_with_roles_on_target(target.id, target.class.name)
        users = actors.select do |a|
          user = CgUser::User.find(a.actor_id)
          aggregate_role = CgRoleClient::Role.aggregate_role(user, target)
          user if aggregate_role.allows?(activity)
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end


    # Return this actor's singleton group. Each actor is associated
    # with a group that only it is a member of.
    def singleton_group
      begin
        Actor.ensure_endpoint
        Actor.endpoint.find_singleton_group_by_actor_id(@id)
      rescue Exception => e
        puts e
        raise
      end
    end
  end

end
