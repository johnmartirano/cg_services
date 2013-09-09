require 'cg_service/helper'

module CgService
  module UnicornHelper
    extend CgService::Helper

    # Set unicorn config for running service +name+.
    #
    # Example in config/unicorn/qa.rb:
    #
    #    require 'cg_service/unicorn_helper'
    #    CgService::UnicornHelper.configure!(self, 'role_service')
    #
    # @param [Unicorn::Configurator] unicorn
    # @param [String] name
    def self.configure!(unicorn, name)
      srvdir = "/srv/www/apps/cg_#{name}/current"
      root = if File.directory?(srvdir)
               srvdir
             else
               Dir.pwd
             end

      # Note: we always want to use the port defined for development
      # when running unicorn, even on qa and production.  The configs
      # for qa and production are now specific to JRuby/glassfish and
      # thus all have the same port.
      unicorn.listen service_config(root)['development']['port']
      unicorn.pid 'tmp/pids/unicorn.pid'
      unicorn.worker_processes 2

      logfile = "log/#{name}.log"
      unicorn.stderr_path logfile
      unicorn.stdout_path logfile
      unicorn.working_directory root
    end
  end
end
