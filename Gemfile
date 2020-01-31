# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'guard'
gem 'guard-minitest'
gem 'minitest'
gem 'minitest-reporters'
gem 'rake', '~> 10.0'
gem 'rdoc', '~> 3.12'
gem 'rubocop', require: false
gem 'simplecov', '~> 0.17.0', require: false

platforms :rbx do
  gem 'rubinius-developer_tools'
  gem 'rubysl', '~> 2.0'
end

instance_eval File.read('Gemfile.local') if File.exist?('Gemfile.local')
