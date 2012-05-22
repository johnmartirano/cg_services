require 'active_record'
require 'activerecord_threadsafe_fix'
require 'cg_service/auto_doc'
require 'cg_service/helper'
require 'optparse'
require 'sinatra/base'
require 'socket'
require 'yaml'
require 'zlib'

# Common operations for CG services.  Most of these are Sinatra apps,
# so this module makes some assumptions about that.  Typically, a
# Sinatra app should do this:
#
#    class App < Sinatra::Base
#      configure do
#        set :root => File.dirname(__FILE__)
#        set :app_file => __FILE__
#      end
#
#      extend CgService
#      ...
#    end
#
# Sinatra apps provide a 'settings' method.  Others must implement
# similar.  Other apps should "include" this module rather than
# "extend".  The configure! method is invoked when a class extends
# this module, and configure! contains more Sinatra-specific stuff.
#
# (As already implemented by Sinatra), this module assumes the
# following methods:
#
# settings - values set with set('key', value) may be accessed at
# settings.key. If the value is a Proc, the value is the result of
# invoking :call.
#
# set(key, value) - set a configuration value in the settings object
# set(hash) - set multiple configuration values in the settings object
#
# disable(key) - equivalent to set(key, false)
# enable(key) - equivalent to set(key, true)
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

  include CgService::Hostname

  def self.extended(app)
    app.send(:include, CgService::AutoDoc)
    app.send(:configure!)
  end

  # Run +app+ as a rack application.  In JRuby, assume the
  # context_root will be set by the servlet container.  In MRI, wrap
  # the sinatra app in Rack::URLMap at the context_root obtained from
  # +app.settings.context_root+.
  #
  # Starts the registration thread.
  #
  # Example, inside config.ru:
  #
  #    CgService.rackup(self, CgRoleService::App)
  #
  # @param [Rack::Builder] builder
  # @param [Class<Sinatra::Base>] klass
  def self.rackup(builder, klass)
    klass.init_registration_thread
    
    if RUBY_PLATFORM =~ /java/
      # assume java container will handle context_root
      builder.run klass
    else
      builder.run Rack::URLMap.new(klass.settings.context_root => klass.new)
    end
  end

  # Perform a settings lookup on app but catch NoMethodErrors
  #
  # @return [Object] the value or nil
  def [](key)
    settings.send(key) rescue nil
  end

  # Conditionally set if there is not already a value.
  def cset(key, value)
    set(key, value) if self[key].nil?
  end

  def apply_defaults
    # defaults, if not already defined in the app
    cset :environment, ENV['RACK_ENV'] || 'development'

    cset :service_config, 'config/service.yml'
    cset :database_config, 'config/database.yml'
    cset :logger_config, 'config/log4j.properties'

    cset :lookup_service_uri, 'http://localhost:5000/'
    cset :lookup_service_version, '1'

    cset :name, 'Unknown'
    cset :description, proc { "#{settings.name} Service" }
    cset :version, '1'

    cset :lease_time_in_sec, 240
    cset :lease_expiry_interval_in_sec, 5

    cset :scheme, 'http'
    cset :host, hostname
    cset :port, '5000'
    cset :context_root, '/'

    cset :uri, proc {
      scheme = settings.scheme
      host = settings.host
      port = settings.port

      # normalize to <no-leading-slash><context><trailing-slash>
      context_root = String.new(settings.context_root)
      context_root += '/' unless context_root.end_with?('/')
      context_root.slice!(0, 1) if context_root.start_with?('/')

      "#{scheme}://#{host}:#{port}/#{context_root}"
    }
  end

  # args are parsed twice since they 1) may set environment which
  # affects service config, and 2) may set port which should
  # override service config.
  def apply_args_and_service_yml
    parse_args!(ARGV.dup) if settings.app_file == $0
    configure_service
    parse_args!(ARGV) if settings.app_file == $0

    # ignore any context root if run directly
    if settings.app_file == $0
      set :context_root, '/'
    else
      disable :run            # disable built-in webserver
    end
  end

  # Called automatically when this module is extended.  Calls other
  # methods to configure a Sinatra app.
  def configure!
    configure do
      apply_defaults
      apply_args_and_service_yml

      configure_database
      configure_logger

      before do
        logger.info {
          request.request_method + "  " + request.url + "  " + request.ip
        }
      end

      after do
        ActiveRecord::Base.clear_active_connections!
      end
    end
    configure :development do
      begin
        require 'sinatra/reloader'
        register Sinatra::Reloader
      rescue LoadError
        puts("Install sinatra-reloader gem.")
      end
    end
  end

  # Set various settings based any commandline arguments
  def parse_args!(args = ARGV)
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.on('-p', '--port PORT', 'Set port of built-in webserver') do |p|
        set :port, p
      end
      opts.on('-e', '-E', '--environment ENV', 'Set the environment') do |e|
        set :environment, e
      end
      opts.on('-s', 'Deprecated') do |_s|
        puts '-s commandline option is deprecated and has no effect'
      end
    end.parse!(args)
  end

  # Apply settings in service config file (default
  # config/service.yml).
  def configure_service
    file = File.join(settings.root, settings.service_config)
    conf = YAML.load_file(file)[settings.environment.to_s]
    conf && conf.each do |key, value|
      set(key, value)
    end
  end

  def configure_database
    file = File.join(settings.root, settings.database_config)
    config = YAML.load_file(file)[settings.environment.to_s]
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.include_root_in_json = false
    ActiveRecord::Base.default_timezone = :utc
    ActiveRecord::Base.time_zone_aware_attributes = true
  end

  def configure_logger
    cattr_accessor :logger
    if RUBY_PLATFORM =~ /java/
      require 'log4j_logger'
      file = File.join(settings.root, settings.logger_config)
      self.logger = Log4jLogger.new file
    else
      require 'logger'
      self.logger = Logger.new(STDOUT)
      self.logger.level = Logger::INFO
    end
    ActiveRecord::Base.logger = self.logger
  end

  # Initialize a thread that will register with a lookup service according to
  #
  # (describe lookup service)
  # settings.lookup_service_uri
  # settings.lookup_service_version
  #
  # (describe this service)
  # settings.name
  # settings.description
  # settings.uri
  # settings.version
  def init_registration_thread

    # Important to not require 'cg_lookup_client' until we're ready to
    # start the registration thread.  This must be done after rackup
    # daemonized so the registration thread runs in the child rather
    # than dying in the parent.
    #
    # FIXME: this thread really needs start/stop controls.
    require 'cg_lookup_client' # starts registration thread
  
    endpoint = CgLookupClient::RestEndpoint.new(settings.lookup_service_uri,
                                                settings.lookup_service_version)
    CgLookupClient::Entry.configure_endpoint(endpoint)

    entry = CgLookupClient::Entry.new(:type_name => settings.name,
                                      :description => settings.description,
                                      :uri => settings.uri,
                                      :version => settings.version)
  
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
        # puts status[:message] + " --  Successfully renewed with CgLookupService endpoint #{status[:endpoint]}."
      end
      if fail_count >= 3
        puts "TODO: An admin should be notified at this point."
      end
    end

    puts "|| CG #{settings.name} Service is starting up on #{settings.uri} ..."
  end

end

