require 'rest-client'
require 'active_record'

module CgLookupClient
  class RestEndpoint

    attr_reader :uri, :version

    def initialize(uri, version)
      @uri = uri
      # ensure trailing slash on uri
      @uri << '/' if @uri[-1].chr != '/'
      # to_s in case a number is passed in
      @version = version.to_s
    end

    def uri_with_version
      @uri + 'v' + @version + "/"
    end

    def register(entry)
      # TODO replace the following comment with a real log statement
      # puts "### registering at #{uri_with_version}"
      registered = nil
      begin
        RestClient.post(uri_with_version + 'entries', entry.to_json,
                        :content_type => :json, :accept => :json) {
            |response, request, result|
          case response.code
            when 200
              registered = CgLookupClient::Entry.new.from_json(response.body)
              yield(registered.id, true, result.message)
            else
              yield(nil, false, ActiveSupport::JSON.decode(result.body))
          end
        }
      rescue => error
        yield(nil, false, error.to_s)
      end
      registered
    end

    def lookup(type_name)
      lookup_results = []
      begin
        RestClient.get(uri_with_version + 'entries/' + type_name,
                       :accept => :json) { |response, request, result,|
          case response.code
            when 200
              entries = ActiveSupport::JSON.decode(response.body)
              entries.each do |entry_attributes|
                lookup_result = Hash.new
                lookup_result[:entry] = CgLookupClient::Entry.new(entry_attributes)
                lookup_result[:message] = result.message
                lookup_results << lookup_result
              end
            else
             lookup_results << {:entry=>nil, :message=>
                 ActiveSupport::JSON.decode(result.body)}
          end
        }
      rescue => error
        lookup_results << {:entry=>nil, :message=>error.to_s}
      end
      lookup_results
    end

    def eql?(object)
      if object.equal?(self)
        return true
      elsif !self.class.equal?(object.class)
        return false
      end

      object.uri_with_version.eql?(uri_with_version)
    end

    def hash
      uri_with_version.hash
    end
  end
end