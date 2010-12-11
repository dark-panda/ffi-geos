
$: << File.dirname(__FILE__)
require 'test_helper'

if defined?(Geos::PreparedGeometry)
  class PreparedGeometryTests < Test::Unit::TestCase
    include TestHelper

    def test_contains_properly
      geom_a = read('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').to_prepared
      geom_b = read('POLYGON((2 2, 2 3, 3 3, 3 2, 2 2))')

      assert(geom_a.contains_properly?(geom_b))

      geom_a = read('POLYGON((2 2, 2 3, 3 3, 3 2, 2 2))').to_prepared
      geom_b = read('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))')

      assert(!geom_a.contains_properly?(geom_b))
    end

    def test_intersects
      geom_a = read('LINESTRING(0 0, 10 10)').to_prepared
      geom_b = read('LINESTRING(0 10, 10 0)')

      assert(geom_a.intersects?(geom_b))
    end
  end
end
