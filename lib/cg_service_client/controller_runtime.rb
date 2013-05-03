require 'cg_service_client/log_subscriber'

# See https://gist.github.com/mnutt/566725
#
# See https://github.com/rails/rails/blob/master/activerecord/lib/active_record/railties/controller_runtime.rb
module CgServiceClient
  module ControllerRuntime
    extend ActiveSupport::Concern

    protected

    def process_action(action, *args)
      LogSubscriber.reset!
      super
    end

    def append_info_to_payload(payload)
      super
      payload[:cg_service_runtime] = LogSubscriber.runtime
      payload[:cg_service_cached_counts] = [LogSubscriber.counts[:cached],
                                            LogSubscriber.counts[:not_cached],
                                            LogSubscriber.counts[:not_cacheable]]
      LogSubscriber.reset!
    end

    module ClassMethods
      def log_process_action(payload)
        messages = super
        runtime = payload[:cg_service_runtime]
        counts = payload[:cg_service_cached_counts]

        if runtime
          messages << ('CgService: %.1fms cached/not/not-cacheable: %d/%d/%d' % [runtime.to_f, *counts])
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  include CgServiceClient::ControllerRuntime
end
