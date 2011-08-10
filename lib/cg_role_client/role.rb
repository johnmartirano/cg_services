require 'active_model'
require 'active_support'
require 'active_support/hash_with_indifferent_access'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Role
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    extend CgServiceClient::Serviceable

    self.include_root_in_json = false

    uses_service("Role","1","CgRoleClient::RestEndpoint")

    ATTRIBUTES = [:id, :group_id, :target_id, :role_type_id, :created_at, :updated_at]

    attr_accessor *ATTRIBUTES

    validates_presence_of :group_id, :target_id, :role_type_id

    class << self
      include Aspect4r

      around :grant, :find_by_user_id do |input, &block |
        begin
          ensure_endpoint
          block.call(input)
        rescue Exception => e
          puts e
          raise
        end
      end

      def grant(role_type, actor_or_group, target)
        group = nil
        if actor_or_group.kind_of? CgRoleClient::Actor
            group = @endpoint.find_singleton_group_by_role_id(actor_or_group.id)
        elsif actor_or_group.kind_of? CgRoleClient::Group
            group = actor_or_group
        end
        role = Role.new
        role.role_type_id = role_type.id
        role.group_id = group.id
        role.target_id = target.id


      end

      def find(actor_or_group, target)
        @endpoint.find_notifications_by_user_id(user_id)
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
