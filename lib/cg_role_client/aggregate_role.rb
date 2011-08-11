require 'set'

module CgRoleClient
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

    def allows?(activity)
      @activities.include?(activity.code)
    end

    def activities
      @activities
    end

    def roles
      @roles
    end
  end
end