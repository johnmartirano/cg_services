module CgServiceClient
  # Service client classes should include Base.  It will then include
  # ActiveModel::Validations, CgServiceClient::Serializable,
  # CgServiceClient::Logger, CgServiceClient::ServiceCall and at the
  # class level, include CgServiceClient::Serviceable
  module Base
    include CgServiceClient::Logger

    def endpoint
      # endpoint is defined in CgServiceClient::Serviceable
      self.class.endpoint
    end

    def with_endpoint(&block)
      # with_endpoint is defined in CgServiceClient::Serviceable
      self.class.with_endpoint(&block)
    end

    def self.included(mod)
      # These can't be included above because magic
      mod.send(:include, CgServiceClient::Serializable)
      mod.send(:include, ActiveModel::Validations)

      mod.send(:extend, CgServiceClient::Serviceable)
    end
  end
end
