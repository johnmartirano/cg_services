require 'active_model'
require 'aspect4r'
require 'cg_role_client/rest_endpoint'
require 'cg_service_client'

module CgRoleClient
  # A target is a reference to an access controlled object.
  class Target
    include CgServiceClient::Base

    uses_service("Role","1",CgRoleClient::RestEndpoint)

    serializable_attr_accessor :target_id, :target_type, :role

    class << self
      def find_by_target_type_and_actor(target_type,user)
        with_endpoint do |endpoint|
          endpoint.find_target_by_target_type_and_actor_type_and_actor_id(target_type,user.class.name,user.id)
        end
      end

      #second two parameters should be lists of CgRoleClient::Activity.foo's and valid CgRoleClient::RoleType.target_type's respectively
      def find_by_actor_activities_and_target_types(user, activities, target_types)
        activity_ids = activities.map &:id
        target_type_strings = target_types.map &:to_s
        with_endpoint do |endpoint|
          endpoint.find_targets_with_activities_for_this_actor(user, activity_ids, target_type_strings)
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end
