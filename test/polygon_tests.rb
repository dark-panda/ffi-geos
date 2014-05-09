# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class PolygonTests < Minitest::Test
  include TestHelper

  def setup
    super
    writer.rounding_precision = 2
  end

  def test_default_srid
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    assert_equal(0, geom.srid)
  end

  def test_setting_srid_manually
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    geom.srid = 4326
    assert_equal(4326, geom.srid)
  end

  def test_dimensions
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    assert_equal(2, geom.dimensions)

    geom = read('POLYGON ((0 0 0, 5 0 0, 5 5 0, 0 5 0, 0 0 0))')
    assert_equal(2, geom.dimensions)
  end

  def test_num_geometries
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    assert_equal(1, geom.num_geometries)
  end
end
