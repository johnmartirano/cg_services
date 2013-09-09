require 'rake'
require 'rubygems/package_task'

def gemspec
  file = 'cg_service.gemspec'
  eval(File.read(file), binding, file)
end

# build non-java version of the gem
Gem::PackageTask.new(gemspec) do |p|
  p.gem_spec = gemspec
end

# build java version of the gem
gemspec.java!.tap do |gemspec|
  Gem::PackageTask.new(gemspec) do |p|
    p.gem_spec = gemspec
  end
end

task :clean => :clobber
