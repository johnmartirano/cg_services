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

      around :create, :find_by_actor_type_and_actor_id, :find_with_roles_on_target, :find_by_target_with_activities do | *args, &block |
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

      # Get all the actors with an activity on a target
      # @param target object
      # @param an Array of Activity
      # @returns an array of Actor
      def find_by_target_with_activities(target, activities)
        target_id = target.id.to_s
        target_type = target.class.name
        activity_ids = activities.map &:id
        @endpoint.find_actors_by_target_and_target_type_and_activities(target_id, target_type, activity_ids)
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
