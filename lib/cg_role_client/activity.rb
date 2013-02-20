require 'active_model'
require 'cg_role_client/rest_endpoint'
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
    include CgServiceClient::Base

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    uses_service("Role", "1", CgRoleClient::RestEndpoint)

    class << self
      # Enables activities to be found using statements
      # such as, Activity.read, Activity.write, etc.
      def method_missing(sym, *args, &block)
        logger.warn "CgRoleClient::Activity.activity is deprecated, use CgRoleClient::Activity[:activity]"
        logger.warn "Called by #{caller.first}"
        self[sym]
      end

      def [](sym)
        begin
          # TODO: Should there be a more general-use cache for caching
          # parsed JSON (rather than simply caching the unparsed
          # HTTP response string).
          #
          # Putting this one in since the activities are used in many
          # places and they never change.
          @cache ||= {}
          @cache[sym.to_s] ||= endpoint.find_activity_by_code(sym.to_s)
        rescue Exception => e
          logger.error e
          logger.error e.backtrace.join("\n\t")
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
