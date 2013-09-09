require 'rest-client'
require 'active_record'

require 'cg_lookup_client/uri_with_version'

module CgLookupClient
  class RestEndpoint
    include UriWithVersion
    
    def initialize(uri, version)
      set_uri_and_version(uri, version)
    end

    alias :to_s :uri_with_version

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
  end
end
