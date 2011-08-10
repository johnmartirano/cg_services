require 'active_model'
require 'active_support'
require 'active_support/hash_with_indifferent_access'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Group
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations

    self.include_root_in_json = false

    ATTRIBUTES = [:id, :code, :name, :created_at, :updated_at]

    attr_accessor *ATTRIBUTES

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
