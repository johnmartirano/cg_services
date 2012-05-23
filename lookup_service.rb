require 'rubygems'
# Allows you to run without bundle exec, we do it here instead
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'active_record'
require 'cg_service'
require 'erb'
require 'sinatra/base'

require "#{File.expand_path(File.dirname(__FILE__))}/models/entry"

# Pretty relative date since ActiveSupport isn't available.
#
# Copied from http://stackoverflow.com/a/195894/454156
module PrettyDate
  def time_ago_in_words
    a = (Time.now-self).to_i

    case a
      when 0 then return 'just now'
      when 1 then return 'a second ago'
      when 2..59 then return a.to_s+' seconds ago' 
      when 60..119 then return 'a minute ago' #120 = 2 minutes
      when 120..3540 then return (a/60).to_i.to_s+' minutes ago'
      when 3541..7100 then return 'an hour ago' # 3600 = 1 hour
      when 7101..82800 then return ((a+99)/3600).to_i.to_s+' hours ago' 
      when 82801..172000 then return 'a day ago' # 86400 = 1 day
      when 172001..518400 then return ((a+800)/(60*60*24)).to_i.to_s+' days ago'
      when 518400..1036800 then return 'a week ago'
    end
    return ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
  end
end

Time.send :include, PrettyDate

module CgLookupService
  class App < Sinatra::Base
    configure do
      set :root => File.dirname(__FILE__)
      set :app_file => __FILE__
    end

    extend CgService

    # Configure expiration thread
    configure do
      set :db_lock, Mutex.new   # FIXME: mutex unnecessary because db txns

      puts "|| CG Lookup Service is starting up..."
      puts "|| Lease time set to " + \
               settings.lease_time_in_sec.to_s + " seconds."
      puts "|| Lease expiry interval set to " + \
               settings.lease_expiry_interval_in_sec.to_s + " seconds.\n\n"

      Thread.new do
        loop do
          sleep settings.lease_expiry_interval_in_sec
          ActiveRecord::Base.connection_pool.with_connection do
            settings.db_lock.synchronize do
              entries = Entry.all
              entries.each do |entry|
                seconds_since_update = Time.now.to_i - entry.updated_at.to_i
                if seconds_since_update > settings.lease_time_in_sec
                  entry.delete
                end
              end
            end
          end
        end
      end
    end

    # get the service documentation
    get '/v1/doc/?', :provides => 'html' do
      @title = 'CG Lookup Service Documentation'
      erb :v1_doc
    end

    # get all entries as html
    get '/v1/entries/?', :provides => 'html' do
      @title = 'CG Lookup Service Entries'
      @entries = Entry.order(:type_name, :uri)
      erb :v1_entries
    end

    # get all entries as json
    get '/v1/entries/?', :provides => 'json' do
      entries = Entry.all
      if entries.length > 0
        entries.to_json
      else
        halt [404, 'No entries were found.'.to_json]
      end
    end

    # get all entries of a certain type
    get '/v1/entries/:type_name/?', :provides => 'json' do
      settings.db_lock.synchronize do
        entries = Entry.find_all_by_type_name(params[:type_name])
        if entries.length > 0
          entries.to_json
        else
          halt [404,
                "No entries of type #{params[:type_name]} were found.".to_json]
        end
      end
    end

    # register or renew an entry
    post '/v1/entries/?', :provides => 'json' do
      settings.db_lock.synchronize do
        begin
          attributes = JSON.parse(request.body.read)
          entry = Entry.find_by_type_name_and_version_and_uri(
              attributes["type_name"], attributes["version"],
              attributes["uri"])
          if entry
            # renew
            entry.touch
            entry.save
            entry.to_json
          else
            # register
            entry = Entry.create(attributes)
            if entry.valid?
              entry.to_json
            else
              halt [422, entry.errors.to_json]
            end
          end
        rescue => e
          puts e.message
          halt [500, e.message.to_json]
        end
      end
    end

    # remove an entry from the registry
    delete '/v1/entries/:id/?', :provides => 'json' do
      settings.db_lock.synchronize do
        entry = Entry.find(params[:id])
        if entry
          entry.destroy
          entry.to_json
        else
          halt [404, "No entry with id #{:id} was found.".to_json]
        end
      end
    end

    # start the server if ruby file executed directly
    run! if app_file == $0

    # used in test cases to speed test execution
    def self.lease_time=(time_in_seconds)
      settings.lease_time_in_sec = time_in_seconds
    end

    def self.lease_expiry_interval=(interval_in_seconds)
      settings.lease_expiry_interval_in_sec = interval_in_seconds
    end

  end

end
