require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Group
    include ActiveModel::Validations
    include Aspect4r # this has to be here for the class level "around" to work
    include CgServiceClient::Serializable
    extend CgServiceClient::Serviceable

    uses_service("Role", "1", "CgRoleClient::RestEndpoint")

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    validates_presence_of :code, :name

    class << self
      include Aspect4r

      around :create, :find_by_code, :method_name_arg => true do |method, *args, &block |
        begin
          ensure_endpoint
          block.call(args[0])
        rescue Exception => e
          puts e
          raise
        end
      end

      def create(attributes = {})
        group = CgRoleClient::Group.new(attributes)
        if !group.valid? || !group.id.nil?
          return false
        end
        @endpoint.create_group(group)
      end

      def find_by_code(group_code)
        @endpoint.find_group_by_code(group_code)
      end

    end

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def actors
      begin
        ensure_endpoint
        @endpoint.find_group_actors_by_group_id(@id)
      rescue Exception => e
        puts e
        raise
      end
    end

    # Might be needed later
=begin
    def roles
      @endpoint.find_group_roles_by_group_id
    end
=end

  end

end
