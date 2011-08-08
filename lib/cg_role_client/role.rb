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

    ATTRIBUTES = [:id, :user_id, :type_id, :heading, :body,
                  :read, :cg_object_id, :cg_object_type, :created_at, :updated_at]

    attr_accessor *ATTRIBUTES

    validates_presence_of :user_id, :type_id, :heading, :body, :read
    validates_length_of :heading, :maximum=>255

    class << self
      include Aspect4r

      around :create, :find_by_user_id, :unread_count do |input, &block |
        begin
          ensure_endpoint
          block.call(input)
        rescue Exception => e
          puts e
          raise
        end
      end

      def create(attributes = {})
        notification = CgNotificationClient::Notification.new(attributes)
        @endpoint.create_notification(notification)
      end

      def find_by_user_id(user_id)
        @endpoint.find_notifications_by_user_id(user_id)
      end

      def unread_count(user_id)
        @endpoint.unread_notifications_count(user_id)
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

      # Save a true read status. Attempting to save a read status of false will result in an
      # IllegalStateError. All previous notifications with a false read status will also be set to true.
      # Other attribute changes will be ignored.
    def save
      begin
        Notification.ensure_endpoint
        if !valid?
          return false;
        end
        if id.nil?
          return Notification.endpoint.create_notification(self)
        end

        if read
          Notification.endpoint.mark_notification_as_read(self)
        else
          raise IllegalStateError, "Cannot set read status to false."
        end
      rescue Exception => e
        puts e
        raise
      end
      true
    end

    def notification_type
      NotificationType.find(@type_id)
    end
  end

  class IllegalStateError < StandardError;
  end

end
