
$: << File.dirname(__FILE__)
require 'test_helper'

class PointTests < Test::Unit::TestCase
  include TestHelper

  def test_default_srid
    geom = read('POINT(0 0)')
    assert_equal(0, geom.srid)
  end

  def test_setting_srid_manually
    geom = read('POINT(0 0)')
    geom.srid = 4326
    assert_equal(4326, geom.srid)
  end

  def test_dimensions
    geom = read('POINT(1 2)')
    assert_equal(0, geom.dimensions)

    geom = read('POINT(1 2 3)')
    assert_equal(0, geom.dimensions)
  end

  def test_num_geometries
    geom = read('POINT(1 2)')
    assert_equal(1, geom.num_geometries)
  end
end
