
$: << File.dirname(__FILE__)
require 'test_helper'

if defined?(Geos::PreparedGeometry)
  class PreparedGeometryTests < Test::Unit::TestCase
    include TestHelper

    POINT_A = 'POINT(0 0)'
    POINT_B = 'POINT(5 0)'
    POINT_C = 'POINT(15 15)'
    LINESTRING_A = 'LINESTRING(0 0, 10 0)'
    LINESTRING_B = 'LINESTRING(5 -5, 5 5)'
    LINESTRING_C = 'LINESTRING(5 0, 15 0)'
    LINESTRING_D = 'LINESTRING(0 0, 5 0, 10 0)'
    POLYGON_A = 'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'
    POLYGON_B = 'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'

    def relationship_tester(method, *expected)
      [
        [ POINT_A, POINT_A ],
        [ POINT_A, LINESTRING_A ],
        [ POINT_B, LINESTRING_A ],
        [ LINESTRING_B, LINESTRING_A ],
        [ LINESTRING_C, LINESTRING_A ],
        [ LINESTRING_D, LINESTRING_A ],
        [ POLYGON_A, POLYGON_B ],
        [ POLYGON_A, POINT_C ],
      ].each_with_index do |(geom_a, geom_b), i|
        geom_a = read(geom_a).to_prepared
        geom_b = read(geom_b)

        value = geom_a.send(method, geom_b)
        assert_equal(expected[i], value)
      end
    end

    def test_disjoint
      relationship_tester(:disjoint?, false, false, false, false, false, false, false, true)
    end

    def test_touches
      relationship_tester(:touches?, false, true, false, false, false, false, false, false)
    end

    def test_intersects
      relationship_tester(:intersects?, true, true, true, true, true, true, true, false)
    end

    def test_crosses
      relationship_tester(:crosses?, false, false, false, true, false, false, false, false)
    end

    def test_within
      relationship_tester(:within?, true, false, true, false, false, true, false, false)
    end

    def test_contains
      relationship_tester(:contains?, true, false, false, false, false, true, false, false)
    end

    def test_overlaps
      relationship_tester(:overlaps?, false, false, false, false, true, false, true, false)
    end

    def test_covers
      relationship_tester(:covers?, true, false, false, false, false, true, false, false)
    end

    def test_covered_by
      relationship_tester(:covered_by?, true, true, true, false, false, true, false, false)
    end
  end
end
