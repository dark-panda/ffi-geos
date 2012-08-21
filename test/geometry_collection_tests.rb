
$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryCollectionTests < Test::Unit::TestCase
  include TestHelper

  if ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:[])
    def test_geometry_collection_enumerator
      geom = read('GEOMETRYCOLLECTION(POINT(0 0))')
      assert_kind_of(Enumerable, geom.each)
      assert_kind_of(Enumerable, geom.to_enum)
      assert_equal(geom, geom.each {})
    end

    def test_geometry_collection_array
      writer.trim = true
      geom = read('GEOMETRYCOLLECTION(
        LINESTRING(0 0, 1 1, 2 2, 3 3),
        POINT(10 20),
        POLYGON((0 0, 0 5, 5 5, 5 0, 0 0)),
        POINT(10 20)
      )')

      assert_equal('LINESTRING (0 0, 1 1, 2 2, 3 3)', write(geom[0]))
      assert_equal('POINT (10 20)', write(geom[-1]))

      assert_equal([
        'LINESTRING (0 0, 1 1, 2 2, 3 3)',
        'POINT (10 20)'
      ], geom[0, 2].collect { |g| write(g) })

      assert_equal(nil, geom[0, -1])
      assert_equal([], geom[-1, 0])
      assert_equal([
        'POINT (10 20)',
        'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))'
      ], geom[1..2].collect { |g| write(g) })
    end
  end

  if ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:detect)
    def test_geometry_collection_enumerable
      writer.trim = true
      geom = read('GEOMETRYCOLLECTION(
        LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2),
        POINT(10 20),
        POLYGON((0 0, 0 5, 5 5, 5 0, 0 0)),
        POINT(10 20)
      )')

      assert_equal(2, geom.select { |point| point == read('POINT(10 20)') }.length)
    end
  end

  def test_default_srid
    geom = read('GEOMETRYCOLLECTION (POINT(0 0))')
    assert_equal(0, geom.srid)
  end

  def test_setting_srid_manually
    geom = read('GEOMETRYCOLLECTION (POINT(0 0))')
    geom.srid = 4326
    assert_equal(4326, geom.srid)
  end

  def test_dimensions
    geom = read('GEOMETRYCOLLECTION (POINT(0 0))')
    assert_equal(0, geom.dimensions)

    geom = read('GEOMETRYCOLLECTION (LINESTRING(1 2, 3 4))')
    assert_equal(1, geom.dimensions)
  end

  def test_num_geometries
    geom = read('GEOMETRYCOLLECTION (POINT(1 2), LINESTRING(1 2, 3 4))')
    assert_equal(2, geom.num_geometries)
  end
end
