# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_service"
  s.version = "0.6.19"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Shared library code for CG services."
  s.summary     = ""

  s.add_dependency 'activerecord', '~> 3.0.6'
  if RUBY_PLATFORM =~ /java/
    s.add_dependency 'activerecord-jdbc-adapter', '1.2.1'
    s.add_dependency 'activerecord-jdbcpostgresql-adapter'
    s.add_dependency 'jdbc-postgres'
    s.add_dependency 'jruby-openssl'
  else
	  s.add_dependency 'pg'
  	s.add_dependency 'thin', '1.2.8'
	end
  s.add_dependency 'sinatra', '>= 1.2.1'
  s.add_dependency 'sinatra-reloader'
  s.add_dependency 'json', '>=1.4.6'
  s.add_dependency 'cg_lookup_client'
  s.add_dependency 'yard', '~> 0.7.2'

  s.files        = Dir.glob("{lib,spec,templates_custom}/**/*")

  s.require_paths = ['lib']
end
