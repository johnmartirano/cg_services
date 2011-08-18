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

      around :find_by_target_type_and_actor do | *args, &block |
        begin
          ensure_endpoint
          block.call(*args)
        rescue Exception => e
          puts e
          raise
        end
      end

      def find_by_target_type_and_actor(target_type,actor)
        @endpoint.find_target_by_target_type_and_actor_type_and_actor_id(target_type,actor.actor_type,actor.actor_id)
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end