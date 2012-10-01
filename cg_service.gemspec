# -*- encoding: utf-8 -*-i
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "cg_service"
  s.version     = "0.7.20"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["CG Labs"]
  s.email       = ["eng@commongroundpublishing.com"]
  s.description = "Shared library code for CG services."
  s.summary     = ""

  s.add_dependency 'activerecord', '= 3.0.12'
  s.add_dependency 'activerecord_threadsafe_fix', '= 3.0.12.1'
  s.add_dependency 'pg'
  s.add_dependency 'thin', '1.2.8'
  s.add_dependency 'sinatra', '>= 1.2.1'
  s.add_dependency 'sinatra-reloader'
  s.add_dependency 'json', '>=1.4.6'
  s.add_dependency 'cg_lookup_client'
  s.add_dependency 'yard', '~> 0.7.2'

  s.files        = Dir.glob("{lib,spec,templates_custom}/**/*")

  s.require_paths = ['lib']

  def s.remove_dependencies(*names)
    dependencies.delete_if do |d|
      names.include? d.name
    end
  end

  # Set platform to java and add java-specific dependencies.
  #
  # @return [Gem::Specification] self
  def s.java!
    self.platform = 'java'
    add_dependency 'activerecord-jdbc-adapter', '1.2.2.20120613'
    add_dependency 'activerecord-jdbcpostgresql-adapter'
    add_dependency 'jruby-openssl'
    remove_dependencies 'pg', 'thin'
    self
  end
end
