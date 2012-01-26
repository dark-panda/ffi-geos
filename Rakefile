
# -*- ruby -*-

require 'rubygems'

gem 'rdoc', '~> 3.12'

require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'

if RUBY_VERSION >= '1.9'
  begin
    gem 'psych'
  rescue Exception => e
    # it's okay, fall back on the bundled psych
  end
end

$:.push 'lib'

version = File.read('VERSION') rescue ''

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ffi-geos"
    gem.summary = "An ffi wrapper for GEOS, a C++ port of the Java Topology Suite (JTS)."
    gem.description = gem.summary
    gem.email = "dark.panda@gmail.com"
    gem.homepage = "http://github.com/dark-panda/ffi-geos"
    gem.authors =    [ "J Smith" ]
    gem.add_dependency "ffi", "~> 1.0.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc 'Test GEOS interface'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_tests.rb']
  t.verbose = !!ENV['VERBOSE_TESTS']
end

desc 'Build docs'
Rake::RDocTask.new do |t|
  t.title = "ffi-geos #{version}"
  t.main = 'README.rdoc'
  t.rdoc_dir = 'doc'
  t.rdoc_files.include('README.rdoc', 'MIT-LICENSE', 'lib/**/*.rb')
end
