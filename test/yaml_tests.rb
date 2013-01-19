# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class YamlTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_point
    geom = read('POINT(5 7)')
    geom.srid = 4326

    yaml = YAML.dump(geom)
    expected = <<-EOS
--- !ruby/object:Geos::Point
wkt: POINT (5.0000000000000000 7.0000000000000000)
srid: 4326
EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Point, new_geom)
    assert_equal(4326, new_geom.srid)
    assert_equal(5, new_geom.x)
    assert_equal(7, new_geom.y)
  end

  def test_line
    geom = read('LINESTRING (0 0, 10 10)')
    geom.srid = 4326

    yaml = YAML.dump(geom)
    expected = <<-EOS
--- !ruby/object:Geos::LineString
wkt: LINESTRING (0.0000000000000000 0.0000000000000000, 10.0000000000000000 10.0000000000000000)
srid: 4326
    EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::LineString, new_geom)

    assert_equal(2, new_geom.num_points)

    point = geom.point_n(0)
    assert_equal(0, point.x)
    assert_equal(0, point.y)

    point = geom.point_n(1)
    assert_equal(10, point.x)
    assert_equal(10, point.y)
  end

  def test_polygon
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    geom.srid = 4326

    yaml = YAML.dump(geom)
    expected = <<-EOS
--- !ruby/object:Geos::Polygon
wkt: POLYGON ((0.0000000000000000 0.0000000000000000, 5.0000000000000000 0.0000000000000000,
  5.0000000000000000 5.0000000000000000, 0.0000000000000000 5.0000000000000000, 0.0000000000000000
  0.0000000000000000))
srid: 4326
    EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::Polygon, new_geom)

    assert_equal(0, new_geom.num_interior_rings)
    assert_equal(5, new_geom.exterior_ring.num_points)
  end

  def test_geometry_collection
    geom = read('GEOMETRYCOLLECTION (POINT(5 7))')
    geom.srid = 4326

    yaml = YAML.dump(geom)
    expected = <<-EOS
--- !ruby/object:Geos::GeometryCollection
wkt: GEOMETRYCOLLECTION (POINT (5.0000000000000000 7.0000000000000000))
srid: 4326
    EOS
    assert_equal(expected, yaml)

    new_geom = YAML.load(yaml)
    assert_kind_of(Geos::GeometryCollection, new_geom)
    assert_equal(1, new_geom.to_a.count)
    assert_equal(4326, new_geom.srid)
  end
end
