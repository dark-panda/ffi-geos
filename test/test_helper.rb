
require 'rubygems'
require 'test/unit'

if ENV['USE_BINARY_GEOS']
  require 'geos'
else
  require File.join(File.dirname(__FILE__), %w{ .. lib ffi-geos })
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

  def read(geom)
    reader.read(geom)
  end

  def write(geom)
    writer.write(geom)
  end

  def raise_unimplemented
    raise "Not yet implemented" if ENV['UNIMPLEMENTED']
  end
end
