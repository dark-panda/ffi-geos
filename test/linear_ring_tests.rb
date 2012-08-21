$: << File.dirname(__FILE__)
require 'test_helper'

class LinearRingTests < Test::Unit::TestCase
  include TestHelper

  def test_to_polygon
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    ring = geom.exterior_ring

    assert_equal(write(geom), write(ring.to_polygon))
  end
end
