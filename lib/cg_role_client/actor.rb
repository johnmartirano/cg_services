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

      around :create, :find_by_actor_type_and_actor_id, :method_name_arg => true do |method, *args, &block |
        begin
          ensure_endpoint
          if method == 'find_by_actor_type_and_actor_id'
            block.call(args[0],args[1])
          else
            block.call(args[0])
          end
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
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def singleton_group
      begin
        ensure_endpoint
        @endpoint.find_singleton_group_by_actor_id(@actor_id)
      rescue Exception => e
        puts e
        raise
      end
    end
  end

end
