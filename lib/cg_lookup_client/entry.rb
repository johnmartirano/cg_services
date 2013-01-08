require 'thread'
require 'monitor'
require 'set'
require 'active_model'
require 'active_support'
require 'active_support/hash_with_indifferent_access'

module CgLookupClient

  # The client side of the CG Lookup Service. Represents a registered Entry
  # within a Lookup Service instance (endpoint). At least one endpoint must
  # be configured before registration or lookup may be performed. If multiple
  # endpoints are configured, registrations and lookup are performed across
  # all.
  #
  # This class is thread safe.
  class Entry
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations

    self.include_root_in_json = false

    LEASE_RENEWAL_INTERVAL_IN_SEC = 30
    SUPPORTED_ENDPOINT_VERSIONS = ["1"]

      # Guard access to endpoints and entries
    @entries_monitor = Monitor.new # Using Monitor since Mutex is not reentrant

      # Guarded by @entries_monitor
    @endpoints = Set.new
    @entries = Hash.new

    ATTRIBUTES = [:id, :type_name, :description, :uri, :version, :created_at,
                  :updated_at]

    attr_accessor *ATTRIBUTES

    validates_presence_of :uri, :type_name, :version, :description
    validates_length_of :uri, :type_name, :version, :description, :maximum=>255

    class << self
      attr_accessor :entries_monitor, :entries, :endpoints

      # Bind with a lookup service endpoint. Multiple endpoints may be
      # registered, one after another. Currently, only version 1 endpoints are
      # supported. Default is a version 1 endpoint running on localhost:5000.
      def configure_endpoint(endpoint= \
          CgLookupClient::RestEndpoint.new("http://localhost:5000/", "1"))
        if !supported_endpoint_version?(endpoint.version)
          raise UnsupportedEndpointVersionError, \
                       "Version #{endpoint.version} endpoints are not supported."
        end

        @endpoints.add(endpoint)
      end

      def clear_endpoints
        @entries_monitor.synchronize do
          @endpoints.clear
        end
      end

      def clear_entries
        @entries_monitor.synchronize do
          @entries.clear
        end
      end

      def supported_endpoint_version?(version)
        !SUPPORTED_ENDPOINT_VERSIONS.find_index(version).nil?
      end

        # Only provided for testing purposes. Do not call in production code.
      def endpoints
        @endpoints
      end

        # Only provided for testing purposes. Do not call in production code.
      def entries
        @entries
      end
    end

    def initialize(attributes = {})
      self.attributes = attributes
      if !@uri.nil? && @uri.length > 1
        @uri << '/' if @uri[-1].chr != '/'
      end
      @version = @version.to_s
    end

    def attributes
      ATTRIBUTES.inject(
          ActiveSupport::HashWithIndifferentAccess.new) do |result, key|
        attribute_value = read_attribute_for_validation(key)
        result[key] = attribute_value unless attribute_value == nil
        result
      end

    end

    def attributes=(attrs)
      attrs.each_pair { |k, v| send("#{k}=", v) }
    end

    # Register the specified entry with all lookup service
    # endpoints. Renewal is handled automatically after initial
    # registration and continues for the lifetime of the loaded Entry
    # class.
    #
    # Starts a thread to perform periodic renewals in the background
    # if it has not already been started.
    #
    # Required attributes are: type_name (the type of resource),
    # description (implementation details), uri (the location of the
    # resource), and version (version of the resource).
    #
    # A callback block may be optionally passed to this method that
    # takes a single parameter, a hash containing the following keys:
    # 1) endpoint => the address of the endpoint that the Entry was
    # attempted to be registered with, 2) id => the ID of the entry at
    # the specific endpoint, 3) success => whether or not the
    # registration succeeded, and 4) message => any message associated
    # with the result.
    #
    # Returns an Array of Entry instances, as created by the respective
    # endpoints. Thus, a returned Entry will contain an ID set by the endpoint.
    # The ID is of little value, except for removing an Entry from an endpoint,
    # which is not currently supported by this API.
    def register(&callback)
      Entry.ensure_configured
      registered = []
      if valid?
        Entry.entries_monitor.synchronize do
          Entry.entries[self] = callback
          # start renewal thread on first entry
          if Entry.entries.size == 1
            CgLookupClient::Entry.start_renewal_thread
          end
          registered = CgLookupClient::Entry.register_with_all_endpoints(self)
        end
      end
      registered
    end

    # Lookup registered types with the specified version. Lookup is
    # performed across all endpoints. All matching entries found
    # are returned.
    #
    # Returns an Array where each member is a Hash containing the
    # matching entry, and a potential message from the endpoint,
    # typically a success message. If the lookup fails for whatever
    # reason, an error message will be returned instead, along with a
    # nil entry. Hash keys are :entry and :message.
    def self.lookup(type, version)
      Entry.ensure_configured
      lookup_from_all_endpoints(type, version)
    end

    def eql?(object)
      if object.equal?(self)
        return true
      elsif !self.class.equal?(object.class)
        return false
      end

      object.composite_id.eql? composite_id
    end

    def hash
      uri.hash+version.hash+type_name.hash
    end

    def to_s
      composite_id
    end

      # Helper to get the value of a particular attribute.
    def read_attribute_for_validation(key)
      send(key)
    end

    protected

    def composite_id
      uri+'v'+version+'/'+type_name
    end

    private

    def self.ensure_configured
      if @endpoints.empty?
        raise ::CgLookupClient::NoEndpointConfiguredError, "No endpoints are configured. Call Entry.configure_endpoint first."
      end
    end

    def self.lookup_from_all_endpoints(type, version)
      @entries_monitor.synchronize do

        @results = @endpoints.map {|ep| ep.lookup(type) }.flatten #async lookups required?
        @matches = @results.select {|r| !r[:entry].nil? && r[:entry].version == version }
      end
      @matches
    end

    def self.register_with_all_endpoints(entry)
      registered = []
      @entries_monitor.synchronize do

        @endpoints.each do |endpoint|
          callback_hash = {}
          register_result = endpoint.register(entry) do |id, success, message|
            callback_hash[:endpoint] = endpoint.uri_with_version
            callback_hash[:id] = id
            callback_hash[:success] = success
            callback_hash[:message] = message
          end

          unless register_result.nil?
            registered << register_result
          end

            # Any exception that is thrown by the callback block will kill the
            # current thread unless we catch it here. Just print the message.
          begin
            @entries[entry].call(callback_hash) unless @entries[entry].nil?
          rescue Exception => e
            puts e.message
          end
        end
      end
      registered
    end


    def self.register_all_entries
      @entries_monitor.synchronize do
        @entries.each do |entry, message|
          Entry::register_with_all_endpoints(entry)
        end
      end
    end

    def self.start_renewal_thread
      Thread.new do
        loop do
          sleep LEASE_RENEWAL_INTERVAL_IN_SEC
          register_all_entries
        end
      end
    end

  end

    # Error for when user attempts to configure an unsupported endpoint version.
  class UnsupportedEndpointVersionError < StandardError;
  end

  class NoEndpointConfiguredError < StandardError;
  end
end
