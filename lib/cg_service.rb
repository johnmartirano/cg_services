require 'active_record'
require 'sinatra/base'
require 'cg_lookup_client'

module CgService

  module RakeLoader
    class << self
      def load_tasks!
        require 'rake'
        [:db].each do |file|
          load(File.join(File.dirname(__FILE__), "tasks/#{file.to_s}.rake"))
        end
      end
    end
  end 


  module Configure
    # Configure port
    def configure_port(port_number)
      configure do
        port_arg_idx = ARGV.index("-p")
        port_arg = ARGV[port_arg_idx+1] unless port_arg_idx == nil
        set :port, port_arg || port_number
      end
    end

	# Configure database
    def configure_db(db_file)
      configure do
        env_arg_idx = ARGV.index("-e")
        env_arg = ARGV[env_arg_idx+1] unless env_arg_idx == nil
        env = env_arg || ENV["SINATRA_ENV"] || "development"
        databases = YAML.load_file(db_file)
        ActiveRecord::Base.establish_connection(databases[env])
        ActiveRecord::Base.include_root_in_json = false
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.time_zone_aware_attributes = true
      end
    end

	# Configure service
    def configure_service(service_file,service_name)
      configure do
        app_config = YAML.load_file("config/service.yml")
        set :app_file, service_file
        set :lookup_service_uri => app_config["lookup_service_uri"]
        set :lookup_service_version => app_config["lookup_service_version"]
        set :application_service_host => app_config["application_service_host"]
        set :application_service_scheme => app_config["application_service_scheme"]
        set :application_service_uri => \
                settings.application_service_scheme + "://"  \
              + settings.application_service_host + ":"  \
              + settings.port.to_s + "/"
  
        endpoint =
            ::CgLookupClient::RestEndpoint.new(settings.lookup_service_uri, settings.lookup_service_version)
        CgLookupClient::Entry.configure_endpoint(endpoint)
        service_entry = CgLookupClient::Entry.new(
            {:type_name=>service_name,
             :description=>"Sinatra #{service_name} Service",
             :uri=>settings.application_service_uri,
             :version=>"1"})
  
        # The registration thread will warn when renewal fails.
        # TODO: If renewal fails 3 or more times we should notify an admin.
        fail_count=0
        service_entry.register do |status|
          if !status[:success]
            fail_count+=1
            puts status[:message] + " --  Failed #{fail_count} times to connect to CgLookupService endpoint #{status[:endpoint]}."
          else
            fail_count=0
            puts status[:message] + " --  Successfully renewed with CgLookupService endpoint #{status[:endpoint]}."
          end
          if fail_count >= 3
            puts "TODO: An admin should be notified at this point."
          end
        end
  
        puts "|| CG #{service_name} Service is starting up..."
  
      end
    end

	# Configure sinatra reloader for a particular environment, defaults to development.
    def configure_sinatra_reloader(enviro=:development)
      configure(enviro) do
        begin
          require 'sinatra/reloader'
          register Sinatra::Reloader
        rescue LoadError
          puts("Install sinatra-reloader gem.")
        end
      end
    end

  end

end

