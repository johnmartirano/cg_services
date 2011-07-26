# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_service"
  s.version = "0.5.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Shared library code for CG services."
  s.summary     = ""

  s.add_dependency 'activerecord', '>= 3.0.6'
  s.add_dependency 'pg'

  s.files        = Dir.glob("{lib,spec}/**/*")

  s.require_paths = ['lib']
end
