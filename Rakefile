
# -*- ruby -*-

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

$:.push 'lib'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ffi-geos"
    gem.version = "0.0.1.beta1"
    gem.summary = "An ffi wrapper for GEOS, a C++ port of the Java Topology Suite (JTS)."
    gem.description = gem.summary
    gem.email = "dark.panda@gmail.com"
    gem.homepage = "http://github.com/dark-panda/ffi-geos"
    gem.authors =    [ "J Smith" ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc 'Test GEOS interface'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_tests.rb'
  t.verbose = !!ENV['VERBOSE_TESTS']
end

desc 'Build docs'
Rake::RDocTask.new do |t|
  require 'rdoc'
  t.title = 'ffi-geos Documentation'
  t.main = 'README.rdoc'
  t.rdoc_dir = 'doc'
  t.rdoc_files.include('README.rdoc', 'MIT-LICENSE', 'lib/**/*.rb')
end
