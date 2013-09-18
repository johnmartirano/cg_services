require 'gem/dependency_management'

Gem::Specification.new do |s|
  s.name        = "cg_service_client"
  s.version     = "0.6.16"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Client library for CG web service clients."
  s.summary     = ""

  s.set_parent 'scholar'

  s.add_dependency "activemodel"
  s.add_dependency "activesupport"
  s.add_dependency "cg_lookup_client", "~> 0.5.16"
  s.add_dependency "request_store"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.files        = Dir.glob("{lib,spec}/**/*")

  s.require_paths = ['lib']
end
