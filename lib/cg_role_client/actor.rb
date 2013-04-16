require 'active_model'
require 'aspect4r'
require 'cg_role_client/rest_endpoint'
require 'cg_service_client'

module CgRoleClient
  # Actors are granted roles on target objects. It is a polymorphic type which
  # will usually represent CgUser::User but we may use other types as actors
  # in the future.
  class Actor
    include CgServiceClient::Base

    uses_service("Role","1",CgRoleClient::RestEndpoint)

    serializable_attr_accessor :id, :actor_id, :actor_type, :singleton_group_id, :created_at, :updated_at

    validates_presence_of :actor_id, :actor_type

    class << self
      def create(attributes = {})
        actor = CgRoleClient::Actor.new(attributes)
        if !actor.valid? || !actor.id.nil?
          return false
        end
        with_endpoint {|endpoint| endpoint.create_actor(actor) }
      end

      def find_by_actor_type_and_actor_id(actor_type, actor_id)
        with_endpoint do |endpoint|
          endpoint.find_actor_by_actor_type_and_actor_id(actor_type,actor_id)
        end
      end

      def find_with_roles_on_target(target_id, target_type, role_name = nil)
        with_endpoint do |endpoint|
          endpoint.find_with_roles_on_target(target_id, target_type, role_name)
        end
      end

      # Get all the actors with an activity on a target
      # @param target object
      # @param an Array of Activity
      # @returns an array of Actor
      def find_by_target_with_activities(target, activities)
        return [] if target.nil?

        target_id = target.id.to_s
        target_type = target.class.name
        activity_ids = activities.map &:id
        with_endpoint do |endpoint|
          endpoint.find_actors_by_target_and_target_type_and_activities(target_id, target_type, activity_ids)
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end


    # Return this actor's singleton group. Each actor is associated
    # with a group that only it is a member of.
    def singleton_group
      with_endpoint do |endpoint|
        endpoint.find_singleton_group_by_actor_id(@id)
      end
    end
  end

end
