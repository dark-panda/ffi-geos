source 'https://rubygems.org'

gemspec

gem "rdoc", "~> 3.12"
gem "rake", "~> 10.0"
gem "minitest"
gem "minitest-reporters"
gem "guard-minitest"

if RUBY_VERSION >= '1.9'
  gem "simplecov"
end

if File.exists?('Gemfile.local')
  instance_eval File.read('Gemfile.local')
end

