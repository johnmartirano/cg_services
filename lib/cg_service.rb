require 'cg_service/auto_doc'
require 'active_record'
require 'sinatra/base'
require 'yaml'
require 'active_record/disable_connection_pool'

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

  # Initialize a thread that will register with a lookup service according to
  # +config+, which may be a
  # Hash or a string filename that will be loaded using YAML.load_file
  # The old method +start_registration_thread+ is deprecated and should not be used
  # as it does not have facility to provide custom context_root and assumes the context_root
  # to always be '/'
  def self.init_registration_thread(config)
    config = YAML.load_file(config) if config.kind_of? String

    # Important to not require 'cg_lookup_client' until we're ready to
    # start the registration thread.  This must be done after rackup
    # daemonized so the registration thread runs in the child rather
    # than dying in the parent.
    require 'cg_lookup_client' # starts registration thread

    url = config['application_service_url']
    name = config['name'] || 'Unknown'
    description = config['description'] || "#{name} Service"
    version = config['version'] || '1'
    lookup_service_uri = config['lookup_service_uri'] || 'http://localhost:5000/'
    lookup_service_version = config['lookup_service_version'] || '1'

    endpoint = CgLookupClient::RestEndpoint.new(lookup_service_uri,
                                                lookup_service_version)
    CgLookupClient::Entry.configure_endpoint(endpoint)

    entry = CgLookupClient::Entry.new(:type_name => name,
                                      :description => description,
                                      :uri => url,
                                      :version => version)

    # The registration thread will warn when renewal fails.
    # TODO: If renewal fails 3 or more times we should notify an
    # admin.
    fail_count = 0
    entry.register do |status|
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

    puts "|| CG #{name} Service is starting up on #{url} ..."
  end

  # Start a thread that will register with a lookup service according
  # to +host+, +port+, and various keys in +config+, which may be a
  # Hash or a string filename that will be loaded using YAML.load_file
  # This method is deprecated, please use +init_registration_thread+ instead.
  def self.start_registration_thread(host, port, config)
    config = YAML.load_file(config) if config.kind_of? String

    # Important to not require 'cg_lookup_client' until we're ready to
    # start the registration thread.  This must be done after rackup
    # daemonized so the registration thread runs in the child rather
    # than dying in the parent.
    require 'cg_lookup_client' # starts registration thread

    scheme = config['scheme'] || 'http'
    url = "#{scheme}://#{host}:#{port}/"
    name = config['name'] || 'Unknown'
    description = config['description'] || "#{name} Service"
    version = config['version'] || '1'
    lookup_service_uri = config['lookup_service_uri'] || 'http://localhost:5000/'
    lookup_service_version = config['lookup_service_version'] || '1'

    endpoint = CgLookupClient::RestEndpoint.new(lookup_service_uri,
                                                lookup_service_version)
    CgLookupClient::Entry.configure_endpoint(endpoint)
    
    entry = CgLookupClient::Entry.new(:type_name => name,
                                      :description => description,
                                      :uri => url,
                                      :version => version)

    # The registration thread will warn when renewal fails.
    # TODO: If renewal fails 3 or more times we should notify an
    # admin.
    fail_count = 0
    entry.register do |status|
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
    
    puts "|| CG #{name} Service is starting up on #{url} ..."
  end

  module Configure

    def config
      @config ||= YAML.load_file("config/service.yml")
    end

    # Configure port.  This will only apply if the service is executed
    # directly (i.e. not using rackup or unicorn).
    def configure_port(port_number)
      configure do
        set :port, args_port(port_number)
      end
    end

    # Get the port from ARGV or +default_port+. This will only apply
    # if the service is executed directly (i.e. not using rackup or
    # unicorn).
    def args_port(default_port)
      port_arg_idx = ARGV.index("-p")
      port_arg = ARGV[port_arg_idx+1] unless port_arg_idx == nil
      port_arg || default_port
    end

    # Configure database to environment based on:
    # checks for -e flag, then ENV["RACK_ENV"], then ENV["SINATRA_ENV"], then defaults to development
    def configure_db(db_file)
      configure do
        env_arg_idx = ARGV.index("-e")
        env_arg = ARGV[env_arg_idx+1] unless env_arg_idx == nil
        env = env_arg || ENV["RACK_ENV"] || ENV["SINATRA_ENV"] || "development"
        databases = YAML.load_file(db_file)
        ActiveRecord::Base.establish_connection(databases[env])
        ActiveRecord::Base.include_root_in_json = false
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.time_zone_aware_attributes = true
      end
    end

    # Configure log4j logger - intended to work only in JRuby(uses Log4J)
    def configure_logger(logger_config_file)
      cattr_accessor :logger
      if RUBY_PLATFORM =~ /java/
        require 'log4j_logger'
        self.logger = Log4jLogger.new logger_config_file
      else
        require 'logger'
        self.logger = Logger.new(STDOUT)
      end
      ActiveRecord::Base.logger = logger
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

    # Start a thread that will register with a lookup service according
    # to +host+, +port+, and various keys in +config+, which may be a
    # Hash or a string filename that will be loaded using YAML.load_file
    # This method is deprecated, please use +init_registration_thread+ instead
    def start_registration_thread(host, port, config)
      CgService.start_registration_thread(host, port, config)
    end

    # Initialize a thread that will register with a lookup service according to
    # +config+, which may be a
    # Hash or a string filename that will be loaded using YAML.load_file
    # The old method +start_registration_thread+ is deprecated and should not be used
    # as it does not have facility to provide custom context_root and assumes the context_root
    # to always be '/'
    def init_registration_thread(host, port, config)
      CgService.init_registration_thread(config)
    end
  end

end

