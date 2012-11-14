source 'http://rubygems.org'
source 'http://build.commongroundpublishing.com/gems'

gem 'cg_service', '~> 0.7.19'
# gem 'cg_service', :path => '../cg_service'

if RUBY_PLATFORM =~ /java/
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'jruby-openssl'
end

group :development, :test do
  unless RUBY_PLATFORM =~/java/
    gem 'tux'
    gem 'sqlite3'
  end
  gem 'cg_tasks', '~> 2.0.3'
end

group :test do
  gem 'rspec', '>=2.5.0'
  gem 'rack-test', '=0.5.6'
  unless RUBY_PLATFORM =~ /java/
    gem 'debugger'
  end
end

group :deployment do
  gem 'unicorn' unless RUBY_PLATFORM =~ /java/
end
