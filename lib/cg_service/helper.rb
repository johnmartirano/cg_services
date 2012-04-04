require 'yaml'

module CgService
  module Helper
    # Get the fully qualified hostname.
    #
    # @see http://stackoverflow.com/questions/151545/how-can-i-get-the-fqdn-of-the-current-host-in-ruby
    def hostname
      Socket.gethostbyname(Socket.gethostname).first
    end
    
    def service_config(root = Dir.pwd, path = 'config/service.yml')
      YAML.load_file(File.join(root, path))
    end
  end
end
