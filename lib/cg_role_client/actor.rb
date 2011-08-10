require 'active_model'
require 'active_support'
require 'active_support/hash_with_indifferent_access'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Actor
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    extend CgServiceClient::Serviceable

    self.include_root_in_json = false

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    ATTRIBUTES = [:id, :actor_id, :actor_type, :singleton_group_id, :created_at, :updated_at]

    attr_accessor *ATTRIBUTES

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

    def attributes
      ATTRIBUTES.inject(
          ActiveSupport::HashWithIndifferentAccess.new) do |result, key|
        attribute_value = read_attribute_for_validation(key)
        result[key] = attribute_value unless attribute_value == nil
        result
      end
    end

    def attributes=(attrs)
      attrs.each_pair { |k, v| send("#{k}=", v) }
    end

      # Helper to get the value of a particular attribute.
    def read_attribute_for_validation(key)
      send(key)
    end

  end

end
