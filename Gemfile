source 'http://rubygems.org'
source 'http://build.commongroundpublishing.com/gems'

# service
gem 'activerecord', '>= 3.0.6'
gem 'sinatra', '>= 1.2.1'
gem 'sinatra-reloader'#, '0.5.0'
gem 'thin', '=1.2.8'
gem 'json', '=1.4.6'
gem 'cg_service', '>=0.5.4'
#gem 'cg_service', :path => '../cg_service'
gem 'cg_lookup_client', '>=0.5.0'
gem 'sqlite3-ruby', '=1.2.5', :require => 'sqlite3'




group :development, :test do
  gem 'tux'
  gem 'cg_capistrano'
  gem 'capistrano'
end

group :test do
  gem 'rspec', '>=2.6.0'
  gem 'rack-test', '=0.5.6'
  gem 'ruby-debug-base19x'
  gem 'ruby-debug-ide'
end
