require 'active_record'
require 'sinatra/base'
require 'cg_lookup_client'

module CgService

  module RakeLoader
    class << self
      def load_tasks!
        puts 'boo!'
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
  end

end

