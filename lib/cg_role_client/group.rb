require 'active_model'
require 'aspect4r'
require 'cg_role_client/rest_endpoint'
require 'cg_service_client'

module CgRoleClient
  # A group is a container for multiple actors.
  class Group
    include CgServiceClient::Base

    uses_service("Role", "1", CgRoleClient::RestEndpoint)

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    validates_presence_of :code, :name

    class << self
      def create(attributes = {})
        group = CgRoleClient::Group.new(attributes)
        if !group.valid? || !group.id.nil?
          return false
        end
        with_endpoint {|endpoint| endpoint.create_group(group) }
      end

      def find_by_code(group_code)
        with_endpoint do |endpoint|
          endpoint.find_group_by_code(group_code)
        end
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def add(actor)
      with_endpoint do |endpoint|
        endpoint.add_actor_to_group(@id, actor)
      end
    end

    def remove(actor)
      with_endpoint do |endpoint|
        endpoint.remove_actor_from_group(@id, actor)
      end
    end

    def actors
      with_endpoint do |endpoint|
        endpoint.find_group_actors_by_group_id(@id)
      end
    end

    # Might be needed later
=begin
    def roles
      with_endpoint do |endpoint|
        endpoint.find_group_roles_by_group_id
      end
    end
=end

  end
end
