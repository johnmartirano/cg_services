require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

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

      around :create do |input, &block |
        begin
          ensure_endpoint
          block.call(input)
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

    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end
