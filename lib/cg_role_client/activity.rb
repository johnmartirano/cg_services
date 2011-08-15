require 'active_model'
require 'cg_service_client'

module CgRoleClient
  # An activity is some action that is performable by an actor or group.
  # Examples would include read, write, create, etc. There is not a
  # direct link between an actor and an activity. Rather, an actor
  # is granted a role on a particular target. Each role has an
  # associated role type. Role types are associated with activities.
  # So, an actor or group is granted permission to perform activities
  # on a target by means of the role type a role is associated with.
  class Activity
    include ActiveModel::Validations
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    class << self
      def endpoint
        ensure_endpoint
        @endpoint
      end

      # Enables activities to be found using statements
      # such as, Activity.read, Activity.write, etc.
      def method_missing(sym, *args, &block)
        begin
          endpoint.find_activity_by_code(sym.to_s)
        rescue Exception => e
          puts e
          raise
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def eql?(object)
      if object.equal?(self)
        return true
      elsif !self.class.equal?(object.class)
        return false
      end

      object.code.eql? code
    end

    def hash
      code.hash
    end

  end

end
