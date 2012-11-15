# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class LinearRingTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_to_polygon
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    ring = geom.exterior_ring

    assert_equal(write(geom), write(ring.to_polygon))
  end

  def test_to_polygon_with_srid
    writer.trim = true

    wkt = 'LINEARRING (0 0, 5 0, 5 5, 0 5, 0 0)'
    expected = 'POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))'

    srid_copy_tester(:to_polygon, expected, 0, :zero, wkt)
    srid_copy_tester(:to_polygon, expected, 4326, :lenient, wkt)
    srid_copy_tester(:to_polygon,  expected, 4326, :strict, wkt)
  end
end
