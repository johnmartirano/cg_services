# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_service"
  s.version = "0.6.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Shared library code for CG services."
  s.summary     = ""

  s.add_dependency 'activerecord', '>= 3.0.6'
  s.add_dependency 'pg'
  s.add_dependency 'sinatra', '>= 1.2.1'
  s.add_dependency 'sinatra-reloader'
  s.add_dependency 'thin', '~>1.2.8'
  s.add_dependency 'json', '>=1.4.6'
  s.add_dependency 'cg_lookup_client'

  s.files        = Dir.glob("{lib,spec}/**/*")

  s.require_paths = ['lib']
end
