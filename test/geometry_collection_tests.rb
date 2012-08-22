# frozen_string_literal: true

require 'test_helper'

class GeometryCollectionTests < Minitest::Test
  include TestHelper

  def setup
    super
    writer.trim = true
  end

  def test_geometry_collection_enumerator
    skip unless ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:[])

    geom = read('GEOMETRYCOLLECTION(POINT(0 0))')
    assert_kind_of(Enumerable, geom.each)
    assert_kind_of(Enumerable, geom.to_enum)
    assert_equal(geom, geom.each {})
  end

  def test_geometry_collection_array
    skip unless ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:[])

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

    assert_nil(geom[0, -1])
    assert_equal([], geom[-1, 0])
    assert_equal([
      'POINT (10 20)',
      'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))'
    ], geom[1..2].collect { |g| write(g) })
  end

  def test_geometry_collection_enumerable
    skip unless ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:detect)

    writer.trim = true
    geom = read('GEOMETRYCOLLECTION(
      LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2),
      POINT(10 20),
      POLYGON((0 0, 0 5, 5 5, 5 0, 0 0)),
      POINT(10 20)
    )')

    assert_equal(2, geom.select { |point| point == read('POINT(10 20)') }.length)
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

  def test_x_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(8, geom.x_max)
  end

  def test_x_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(12, geom.y_max)
  end

  def test_y_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')

    assert_equal(0, geom.y_min)
  end

  def test_z_max
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')
    assert_equal(0, geom.z_max)

    geom = read('GEOMETRYCOLLECTION Z (
      POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)),
      LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0),
      POINT Z (3 12 6)
    )')
    assert_equal(6, geom.z_max)

    # GEOS lets you mix dimensionality, while PostGIS doesn't.
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12 10)
    )')
    assert_equal(10, geom.z_max)
  end

  def test_z_min
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12)
    )')
    assert_equal(0, geom.z_min)

    geom = read('GEOMETRYCOLLECTION Z (
      POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0)),
      LINESTRING Z (0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0),
      POINT Z (3 12 6)
    )')
    assert_equal(0, geom.z_min)

    # GEOS lets you mix dimensionality, while PostGIS doesn't.
    geom = read('GEOMETRYCOLLECTION (
      POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0)),
      LINESTRING (0 0, 5 0, 8 9, -10 5, 0 0),
      POINT(3 12 -10)
    )')
    assert_equal(-10, geom.z_min)
  end
end
