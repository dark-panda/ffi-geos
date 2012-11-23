source 'https://rubygems.org'

gemspec

gem "rdoc"
gem "rake", ["~> 0.9"]
gem "minitest"
gem "minitest-reporters"
gem "guard-minitest"

if RbConfig::CONFIG['host_os'] =~ /^darwin/
  gem "rb-fsevent"
  gem "growl"
end

if File.exists?('Gemfile.local')
  instance_eval File.read('Gemfile.local')
end

