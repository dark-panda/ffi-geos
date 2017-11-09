# encoding: BINARY; frozen_string_literal: true

if RUBY_VERSION >= '1.9'
  require 'simplecov'

  SimpleCov.command_name('Unit Tests')
  SimpleCov.merge_timeout(3600)
  SimpleCov.start do
    add_filter '/test/'
    add_filter '/.bundle/'
  end
end

require 'rubygems'
require 'minitest/autorun'
require 'minitest/reporters' if RUBY_VERSION >= '1.9'

if ENV['USE_BINARY_GEOS']
  require 'geos'
else
  require File.join(File.dirname(__FILE__), %w{ .. lib ffi-geos })
end

puts "Ruby version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "ffi version #{Gem.loaded_specs['ffi'].version}" if Gem.loaded_specs['ffi']

if Geos.respond_to?(:version)
  puts "GEOS version #{Geos.version}"
else
  puts "GEOS version #{Geos::GEOS_VERSION}"
end

puts "ffi-geos version #{Geos::VERSION}" if defined?(Geos::VERSION)

if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_path}"
end

module TestHelper
  TOLERANCE = 0.0000000000001

  def self.included(base)
    base.class_eval do
      attr_reader :reader, :reader_hex, :writer
    end
  end

  def setup
    GC.start
    @reader = Geos::WktReader.new
    @reader_hex = Geos::WkbReader.new
    @writer = Geos::WktWriter.new
  end

  def read(*args)
    if args[0][0] != '0'
      reader.read(*args)
    else
      reader_hex.read_hex(*args)
    end
  end

  def write(*args)
    writer.write(*args)
  end

  def geom_from_geom_or_wkt(geom_or_wkt)
    if geom_or_wkt.is_a?(String)
      read(geom_or_wkt)
    else
      geom_or_wkt
    end
  end

  def srid_copy_tester(method, expected, expected_srid, srid_policy, wkt, *args)
    geom = read(wkt)
    geom.srid = 4326
    Geos.srid_copy_policy = srid_policy
    geom_b = geom.send(method, *args)
    assert_equal(4326, geom.srid)
    assert_equal(expected_srid, geom_b.srid)
    assert_equal(expected, write(geom_b))
  ensure
    Geos.srid_copy_policy = :default
  end

  {
    :empty => 'to be empty',
    :valid => 'to be valid',
    :simple => 'to be simple',
    :ring => 'to be ring',
    :closed => 'to be closed',
    :has_z => 'to have z dimension'
  }.each do |t, m|
    self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
      def assert_geom_#{t}(geom)
        assert(geom.#{t}?, "Expected geom #{m}")
      end

      def refute_geom_#{t}(geom)
        assert(!geom.#{t}?, "Did not expect geom #{m}")
      end
    EOF
  end

  def assert_geom_eql_exact(geom, result, tolerance = TOLERANCE)
    assert(geom.eql_exact?(result, tolerance), "Expected geom.eql_exact? to be within #{tolerance}")
  end

  def simple_tester(method, expected, geom, *args)
    geom = geom_from_geom_or_wkt(geom)
    result = geom.send(method, *args)

    if result.is_a?(Geos::Geometry)
      result = write(result)
    end

    assert_equal(expected, result)
  end

  def simple_bang_tester(method, expected, wkt, *args)
    geom = read(wkt)
    result = geom.send(method, *args)

    assert_equal(wkt, write(geom))
    assert_equal(expected, write(result))

    geom = read(wkt)
    geom.send("#{method}!", *args)

    assert_equal(expected, write(geom))
  end

  def comparison_tester(method, expected, geom_a, geom_b, *args)
    geom_a = geom_from_geom_or_wkt(geom_a)
    geom_b = geom_from_geom_or_wkt(geom_b)

    simple_tester(method, expected, geom_a, geom_b, *args)
  end

  def array_tester(method, expected, geom, *args)
    geom = geom_from_geom_or_wkt(geom)
    result = geom.send(method, *args)

    case result
      when Geos::Geometry
        result = [ write(result) ]
      when Array
        result = result.collect { |r|
          write(r)
        }
    end

    assert_equal(expected, result)
  end
end

if RUBY_VERSION >= '1.9'
  Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new)
end

