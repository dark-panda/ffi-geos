
require 'rubygems'
require 'test/unit'

if ENV['USE_BINARY_GEOS']
  require 'geos'
else
  require File.join(File.dirname(__FILE__), %w{ .. lib ffi-geos })
end

puts "Ruby version #{RUBY_VERSION} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "ffi version #{Gem.loaded_specs['ffi'].version}" if Gem.loaded_specs['ffi']
puts "GEOS version #{Geos::GEOS_VERSION}"
puts "ffi-geos version #{Geos::VERSION}" if defined?(Geos::VERSION)
if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_path}"
end

module TestHelper
  TOLERANCE = 0.0000000000001

  def self.included(base)
    base.class_eval do
      attr_reader :reader, :writer
    end
  end

  def setup
    GC.start
    @reader = Geos::WktReader.new
    @writer = Geos::WktWriter.new
  end

  def read(*args)
    reader.read(*args)
  end

  def write(*args)
    writer.write(*args)
  end
end
