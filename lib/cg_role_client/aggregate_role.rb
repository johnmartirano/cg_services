require 'set'

module CgRoleClient
  # An aggregate role encapsulates the all the roles
  # that a particular actor or group may have on a target.
  # This allows for convenient querying of the aggregate
  # role for certain activities the actor or group
  # is allowed to perform.
  class AggregateRole

    def initialize(roles=[])
      @roles = roles
      @activities = Set.new
      roles.each do |role|
        role.role_type.activities.each do |activity|
          @activities.add(activity.code)
        end
      end
    end

    # Test if this aggregate role allows a certain
    # certain activity, such as read, or write.
    # Example: role.allows?(CgRoleClient::Activity.read)
    def allows?(activity)
      @activities.include?(activity.code)
    end

    def activities
      @activities
    end

    def roles
      @roles
    end

    # Get the role that is associated with the specified
    # role type name.
    def role_for(role_name)
      @roles.each do |role|
        if role.role_type.role_name == role_name.gsub(/\b\w/){$&.upcase}
          return role
        end
      end
    end
  end
end