require 'rack/handler'
require 'yaml'
require 'cg_service'

module Rack
  module Handler
    # A Rack Handler that reads the port from options and starts a
    # thread that continually registers the service url and port with
    # a lookup service.
    #
    # Also provides options to redirect stdout and stderr to a log file.
    #
    # Transfers control to another rack handler (e.g. thin) after
    # completing its initialization.
    class CgService
      def self.run(app, options={})
        # Optionally redirect stdout and stderr to log files
        options[:stdout_path].tap do |stdout_path|
          STDOUT.reopen(stdout_path, 'a') if stdout_path
          STDOUT.sync = true
        end
        options[:stderr_path].tap do |stderr_path|
          STDERR.reopen(stderr_path, 'a') if stderr_path
          STDERR.sync = true
        end

        config = options[:service_config] || 'config/server.yml'
        ::CgService.start_registration_thread(options[:Host], options[:Port], config)

        server ||= Rack::Handler.get(options[:transfer]) || Rack::Handler.default(options)
        server.run(app, options)
      end

      def self.valid_options
        {
          "Host=HOST" => "Hostname to listen on (default: localhost)",
          "Port=PORT" => "Port to listen on (default: 8080)",
          "transfer=SERVER" => "Server to transfer to after starting registration thread",
          "service_config=FILE" => "Absolute path to service.yml file",
          "stdout_path=FILE" => "Absolute path where stdout will be redirected",
          "stderr_path=FILE" => "Absolute path where stdout will be redirected",
        }
      end
    end
  end

  Rack::Handler.register('cg_service', Rack::Handler::CgService)

end
