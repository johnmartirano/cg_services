# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_role_client"
  s.version = "0.6.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Client library for the CG Role Service."
  s.summary     = ""

  s.add_dependency "activemodel", ">= 3.0.0"
  s.add_dependency "activerecord", ">= 3.0.0"
  s.add_dependency "activesupport", ">= 3.0.0"
  s.add_dependency "aspect4r", ">= 0.9.1"
  s.add_dependency "rest-client", ">= 1.6.3"
  s.add_dependency "cg_lookup_client", ">= 0.5.0"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.5.0'

  s.files        = Dir.glob("{lib,spec}/**/*")

  s.require_paths = ['lib']
end
