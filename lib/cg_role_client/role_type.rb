require 'active_model'
require 'active_support'
require 'active_support/hash_with_indifferent_access'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class RoleType
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    extend CgServiceClient::Serviceable

    self.include_root_in_json = false

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    ATTRIBUTES = [:id, :role_name, :target_type, :created_at, :updated_at]

    attr_accessor *ATTRIBUTES

    validates_presence_of :role_name, :target_type
    validates_length_of :role_name, :target_type, :maximum=>255

    class << self
      include Aspect4r

      around :all, :find, :method_name_arg => true do |method, *input,
        &block |
        begin
          ensure_endpoint
            # include here methods that take no arguments
          if method == 'all'
            block.call
          else
            block.call(input[0])
          end
        rescue Exception => e
          puts e
          raise
        end
      end

      def all
        @endpoint.find_all_role_types
      end

      def find(id)
        @endpoint.find_role_type_by_id(id)
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

    def activities
      begin
        RoleType.ensure_endpoint
        RoleType.endpoint.find_role_type_activities_by_role_type_id(@id)
      rescue Exception => e
        puts e
        raise
      end
    end

  end

  class IllegalStateError < StandardError;
  end

end
