require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient
  # A target is a reference to an access controlled object.
  class Target
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    serializable_attr_accessor :target_id, :target_type

    class << self
      include Aspect4r

      around :find_by_target_type_and_actor, :find_by_actor_activities_and_target_types do | *args, &block |
        begin
          block.call(*args)
        rescue Errno::ECONNREFUSED => e
          begin
            ensure_endpoint
            block.call(*args)
          rescue Exception=> e
            puts e
            raise
          end
        rescue Exception => e
          puts e
          raise
        end
      end

      def find_by_target_type_and_actor(target_type,actor)
        endpoint.find_target_by_target_type_and_actor_type_and_actor_id(target_type,actor.actor_type,actor.actor_id)
      end

      def find_by_actor_activities_and_target_types(actor, activities, target_types)#second two parameters should be lists of CgRoleClient::Activity.foo's and valid CgRoleClient::RoleType.target_type's respectively
        activity_ids = activities.map &:id
        target_type_strings = target_types.map &:to_s
        endpoint.find_targets_with_activities_for_this_actor(actor, activity_ids, target_type_strings)
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end
