# doesn't exist in 3.1
# require 'active_support/per_thread_registry'

module CgServiceClient
  # Copied from Rails 3.2.  FIXME: remove after upgrade
  module PerThreadRegistry
    protected

    def method_missing(name, *args, &block) # :nodoc:
      # Caches the method definition as a singleton method of the receiver.
      define_singleton_method(name) do |*a, &b|
        per_thread_registry_instance.public_send(name, *a, &b)
      end

      send(name, *args, &block)
    end

    private

    def per_thread_registry_instance
      Thread.current[name] ||= new
    end
  end

  # This is a thread locals registry for CgServiceClient.
  #
  # See the documentation of <tt>ActiveSupport::PerThreadRegistry</tt>
  # for further details.
  class RuntimeRegistry # :nodoc:
    # extend ActiveSupport::PerThreadRegistry
    extend PerThreadRegistry
    
    attr_accessor :runtime, :counts
  end
end
