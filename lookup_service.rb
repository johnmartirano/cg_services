require 'rubygems'
require 'bundler/setup'
require 'erb'
require 'active_record'
require 'sinatra/base'

require "#{File.dirname(__FILE__)}/models/entry"

module CgLookupService
  class App < Sinatra::Base
    # Configure port
    configure do
      port_arg_idx = ARGV.index("-p")
      port_arg = ARGV[port_arg_idx+1] unless port_arg_idx == nil
      set :port, port_arg || 5000
    end

    # Configure database
    configure do
      env_arg_idx = ARGV.index("-e")
      env_arg = ARGV[env_arg_idx+1] unless env_arg_idx == nil
      env = env_arg || ENV["SINATRA_ENV"] || "development"
      databases = YAML.load_file("config/database.yml")
      ActiveRecord::Base.establish_connection(databases[env])
      ActiveRecord::Base.include_root_in_json = false
    end

    # Configure expiration thread
    configure do
      app_config = YAML.load_file("config/service.yml")
      set :app_file, __FILE__
      set :db_lock, Mutex.new
      set :lease_time_in_sec => app_config["lease_time_in_sec"]
      set :lease_expiry_interval_in_sec =>
              app_config["lease_expiry_interval_in_sec"]

      puts "|| CG Lookup Service is starting up..."
      puts "|| Lease time set to " + \
               settings.lease_time_in_sec.to_s + " seconds."
      puts "|| Lease expiry interval set to " + \
               settings.lease_expiry_interval_in_sec.to_s + " seconds.\n\n"

      Thread.new do
        loop do
          sleep settings.lease_expiry_interval_in_sec
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

    configure(:development) do
      begin
        require 'sinatra/reloader'
        register Sinatra::Reloader
      rescue LoadError
        puts("Install sinatra-reloader gem.")
      end
    end

    before do
      puts request.request_method + "  " + request.url + "  " + request.ip
    end

    # get the service documentation
    get '/v1/doc/?', :provides => 'html' do
      @title = 'CG Lookup Service Documentation'
      erb :v1_doc
    end

    # get all entries as html
    get '/v1/entries/?', :provides => 'html' do
      @title = 'CG Lookup Service Entries'
      @entries = Entry.all
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

__END__

