require 'cg_service/helper'

module CgService
  # In your console-mux script, you can include this helper like this:
  #
  #     require 'cg_service/console_mux_helper'
  #     extend CgService::ConsoleMuxHelper
  #
  #     run_service(:name => 'role')
  #
  # A run command using rackup will be created, and the port will
  # configured from config/services.yml.
  module ConsoleMuxHelper
    include CgService::Helper

    def run_service(opts)
      unless opts[:name]
        raise ArgumentError, 'please specify :name'
      end

      env = if opts[:env] && opts[:env]['RACK_ENV']
              opts[:env]['RACK_ENV']
            else
              'development'
            end

      unless opts[:chdir]
        opts[:chdir] = "services/cg_#{opts[:name]}_service"
      end

      config = service_config(opts[:chdir])
      run("rackup -p #{config[env]['port']}", opts)
    end
  end
end
