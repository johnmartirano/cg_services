require 'active_model'
require 'active_support/hash_with_indifferent_access'

module CgServiceClient
  # Mixin to give #as_json, #to_json, and #from_json methods.
  # Attributes that should be serialized must be created with
  # serializable_attr_accessor.
  module Serializable
    def self.included(receiver)
      receiver.extend ClassMethods

      # Can't simply include this inside Serializable because of
      # stuff done by JSON on include (needs a Class, not Module)
      receiver.send(:include, ActiveModel::Serializers::JSON)
      receiver.send(:include_root_in_json=, false)
    end

    module ClassMethods
      def attribute_keys
        @attribute_keys ||= []
      end

      # Define getter and setter methods for each +sym+.  Also make
      # these serializable to and from JSON.
      def serializable_attr_accessor(*syms)
        attr_accessor(*syms)
        attribute_keys.push(*syms)
      end
    end

    # Get the keys for serializeable attributes
    def attribute_keys
      self.class.attribute_keys
    end

    # Used by ActiveModel::Serialization do get the keys that should
    # go into the serialized representation.
    def attributes
      # Note: the values returned here are ignored by
      # ActiveModel::Serializers#serializable_hash; just the keys are
      # used to again call those getter methods...  But we do want to
      # check the values so we can leave 'nil' out of the hash.
      attribute_keys.inject(
          ActiveSupport::HashWithIndifferentAccess.new) do |result, key|
        value = send(key)
        result[key] = value unless value == nil
        result
      end
    end

    def attributes=(attrs)
      attrs.each_pair { |k, v| send("#{k}=", v) }
    end
  end
end
