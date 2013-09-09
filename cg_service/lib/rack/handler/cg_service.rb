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
        reopen = lambda do |file, path|
          if path
            ::File.open(path, 'a') { |f| file.reopen(f) }
            file.sync = true
          end
        end

        # Optionally redirect stdout and stderr to log files
        reopen.call($stdout, options[:stdout_path])
        reopen.call($stderr, options[:stderr_path])

        if app.respond_to? :init_registration_thread
          app.init_registration_thread
        end

        server ||= Rack::Handler.get(options[:transfer]) || Rack::Handler.default(options)
        server.run(app, options)
      end

      def self.valid_options
        {
          "Host=HOST" => "Hostname to listen on (default: localhost)",
          "Port=PORT" => "Port to listen on (default: 8080)",
          "transfer=SERVER" => "Server to transfer to after starting registration thread",
          "stdout_path=FILE" => "Absolute path where stdout will be redirected",
          "stderr_path=FILE" => "Absolute path where stdout will be redirected",
        }
      end
    end
  end

  Rack::Handler.register('cg_service', Rack::Handler::CgService)

end
