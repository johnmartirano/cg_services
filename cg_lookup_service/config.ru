require "#{File.expand_path(File.dirname(__FILE__))}/lookup_service.rb"

if RUBY_PLATFORM =~ /java/
  run CgLookupService::App
else
  # Make app available at '/' and '/lookup_service' for backward
  # compatibility during the transition to JRuby.
  app = CgLookupService::App.new
  run Rack::URLMap.new(CgLookupService::App.settings.context_root => app,
                       '/' => app)
end

