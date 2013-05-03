require 'cg_service_client/runtime_registry'

# See https://gist.github.com/mnutt/566725 also
# cg_community/config/initializers/instrumentation_hook, which formed
# the basis of this class.
module CgServiceClient
  class LogSubscriber < ActiveSupport::LogSubscriber
    def service_call(event)
      self.class.runtime += event.duration

      case event.payload[:cached]
      when true
        self.class.counts[:cached] += 1
      when false
        self.class.counts[:not_cached] += 1
      when nil
        self.class.counts[:not_cacheable] += 1
      end

      return unless logger.debug?

      prefix = case event.payload[:cached]
               when true then 'Cached Service Call'
               when false then 'Service Call'
               when nil then 'Uncacheable Service Call'
               else 'Unknown Service Call'
               end
      
      name = '%s (%.1fms)' % [prefix, event.duration]
      debug "  #{color(name, GREEN, true)}  [ url: #{color(event.payload[:url], BOLD, true)} params: #{event.payload[:params].inspect} ]"
    end

    def self.runtime=(value)
      CgServiceClient::RuntimeRegistry.runtime = value
    end

    def self.runtime
      CgServiceClient::RuntimeRegistry.runtime ||= 0
    end

    def self.counts
      CgServiceClient::RuntimeRegistry.counts ||= Hash.new(0)
    end

    def self.reset!
      runtime = 0
      counts.clear
    end
  end
end

CgServiceClient::LogSubscriber.attach_to :cgservice
