source 'https://rubygems.org'

gemspec

gem "rdoc", "~> 3.12"
gem "rake", "~> 10.0"
gem "minitest"
gem "minitest-reporters"

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end


if RUBY_VERSION >= '1.9'
  gem "simplecov"
  gem "guard"
  gem 'guard-minitest'
end

if File.exists?('Gemfile.local')
  instance_eval File.read('Gemfile.local')
end

