require 'active_model'
require 'aspect4r'
require 'cg_service_client'

module CgRoleClient

  class Activity
    include ActiveModel::Validations
    include CgServiceClient::Serializable

    serializable_attr_accessor :id, :code, :name, :created_at, :updated_at

    def initialize(attributes = {})
      self.attributes = attributes
    end

  end

end
