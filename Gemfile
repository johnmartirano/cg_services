source 'http://rubygems.org'
source 'http://build.commongroundpublishing.com/gems'

gem 'cg_service', '0.6.18'

group :development, :test do
  unless RUBY_PLATFORM =~/java/
    gem 'tux'
    gem 'sqlite3'
  end
  gem 'cg_capistrano', '~> 0.1.79'
  gem 'capistrano_database_yml'
  gem 'warbler', '1.3.2' if RUBY_PLATFORM =~ /java/
end

group :test do
  gem 'rspec', '>=2.5.0'
  gem 'rack-test', '=0.5.6'
  unless RUBY_PLATFORM =~ /java/
    gem 'ruby-debug19'
    gem 'ruby-debug-ide'
  end
  gem 'factory_girl'
end

group :deployment do
  gem 'unicorn' unless RUBY_PLATFORM =~ /java/
end
