
# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_lookup_client"
  s.version = "0.5.20"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Client library for the CG Lookup Service."
  s.summary     = ""

  s.add_dependency "rake", "0.8.7"
  s.add_dependency "rspec", ">= 2.5.0"
  s.add_dependency "rest-client", ">= 1.6.3"
  s.add_dependency "activemodel", ">= 3.0.0"
  s.add_dependency "activerecord", ">= 3.0.0"

  s.files        = Dir.glob("{lib,spec}/**/*")

  s.require_paths = ['lib']
end
