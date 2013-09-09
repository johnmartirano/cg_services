require 'rest-client'
require 'active_record'

module CgLookupClient
  # Classes that include this module should call #set_uri_and_version
  # in their initialize method.  Then the methods #uri, #version,
  # #uri_with_version will be available.
  #
  # This module also defines #eql?, #==, and #hash that work off
  # #uri_with_version.
  module UriWithVersion
    attr_reader :uri, :version, :uri_with_version

    def set_uri_and_version(uri, version)
      if @uri || @version || @uri_with_version
        raise 'cannot set uri and version a second time'
      end

      @uri = uri.dup.freeze
      @version = version.to_s.dup.freeze
      update_uri_with_version
    end

    # This should not be normally called, but may be when initializing
    # from a hash (from json perhaps).
    def uri=(uri)
      @uri = uri.to_s.dup.freeze
      update_uri_with_version
    end

    def version=(version)
      @version = version.to_s.dup.freeze
      update_uri_with_version
    end

    def with_trailing_slash(str)
      if str.nil?
        '/'
      elsif str.end_with?('/')
        str
      else
        str + '/'
      end
    end

    # Test if +object+ is the same class and has the same
    # +uri_with_version+ as self. #eql? is used by Hash.
    def eql?(object)
      if object.equal?(self)
        return true
      elsif self.class.equal?(object.class)
        uri_with_version.eql?(object.uri_with_version)
      end
    end
    alias :== :eql?

    def hash
      uri_with_version.hash
    end

    private

    def update_uri_with_version
      @uri_with_version = "#{with_trailing_slash(@uri)}v#{@version}/".freeze
    end
  end
end
