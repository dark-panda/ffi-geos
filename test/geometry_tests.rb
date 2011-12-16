
$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryTests < Test::Unit::TestCase
  include TestHelper

  def comparison_tester(method_with_args, geom_a, geom_b, expected)
    method_with_args = Array(method_with_args)
    method = method_with_args.shift
    args = method_with_args

    geom_1 = read(geom_a)
    geom_b = read(geom_b)
    result = geom_1.send(method, geom_b, *args)
    assert(read(expected).eql_exact?(result, TOLERANCE))
  end

  def self_tester(method_with_args, g, expected)
    method_with_args = Array(method_with_args)
    geom = read(g)
    result = geom.send(*method_with_args)
    assert(read(expected).eql_exact?(result, TOLERANCE))
  end

  def test_intersection
    comparison_tester(
      :intersection,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))',
      'POLYGON((5 10, 10 10, 10 5, 5 5, 5 10))'
    )
  end

  def test_buffer
    tester = lambda { |expected, geom, *args|
      width, params = args
      assert_equal(expected, write(read(geom).buffer(width, params)))
    }

    @writer.rounding_precision = 0

    tester['POLYGON EMPTY', 'POINT(0 0)', 0]

    tester[
      'POLYGON ((10 0, 10 -2, 9 -4, 8 -6, 7 -7, 6 -8, 4 -9, 2 -10, 0 -10, -2 -10, -4 -9, -6 -8, -7 -7, -8 -6, -9 -4, -10 -2, -10 -0, -10 2, -9 4, -8 6, -7 7, -6 8, -4 9, -2 10, -0 10, 2 10, 4 9, 6 8, 7 7, 8 6, 9 4, 10 2, 10 0))',
      'POINT(0 0)',
      10
    ]

    # One segment per quadrant
    tester[
      'POLYGON ((10 0, 0 -10, -10 -0, -0 10, 10 0))',
      'POINT(0 0)',
      10,
      { :quad_segs => 1 }
    ]

    # End cap styles
    tester[
      'POLYGON ((100 10, 110 0, 100 -10, 0 -10, -10 0, 0 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :round }
    ]

    tester[
      'POLYGON ((100 10, 100 -10, 0 -10, 0 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :flat }
    ]

    tester[
      'POLYGON ((100 10, 110 10, 110 -10, 0 -10, -10 -10, -10 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :square }
    ]

    # Join styles
    tester[
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 0, 107 -7, 100 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :round }
    ]

    tester[
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 0, 100 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :bevel }
    ]

    tester[
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :mitre }
    ]

    tester[
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 109 -5, 105 -9, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :mitre, :mitre_limit => 1.0 }
    ]

    # Single-sided buffering
    tester[
      'POLYGON ((100 0, 0 0, 0 10, 100 10, 100 0))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :single_sided => true }
    ]

    tester[
      'POLYGON ((0 0, 100 0, 100 -10, 0 -10, 0 0))',
      'LINESTRING(0 0, 100 0)',
      -10,
      { :single_sided => true }
    ]
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:offset_curve)
    def test_offset_curve
      tester = lambda { |expected, g, width, style|
        geom = read(g)
        buffered = geom.offset_curve(width, style)

        assert_equal(expected, write(buffered))
      }

      @writer.rounding_precision = 0

      # straight left
      tester[
        'LINESTRING (0 2, 10 2)',
        'LINESTRING (0 0, 10 0)',
        2, {
          :quad_segs => 0,
          :join => :round,
          :mitre_limit => 2
        }
      ]

      # straight right
      tester[
        'LINESTRING (10 -2, 0 -2)',
        'LINESTRING (0 0, 10 0)',
        -2, {
          :quad_segs => 0,
          :join => :round,
          :mitre_limit => 2
        }
      ]

      # outside curve
      tester[
        'LINESTRING (12 10, 12 0, 10 -2, 0 -2)',
        'LINESTRING (0 0, 10 0, 10 10)',
        -2, {
          :quad_segs => 1,
          :join => :round,
          :mitre_limit => 2
        }
      ]

      # inside curve
      tester[
        'LINESTRING (0 2, 8 2, 8 10)',
        'LINESTRING (0 0, 10 0, 10 10)',
        2, {
          :quad_segs => 1,
          :join => :round,
          :mitre_limit => 2
        }
      ]
    end
  end

  def test_convex_hull
    geom = read('POINT(0 0)')
    assert(read('POINT(0 0)').eql_exact?(geom.convex_hull, TOLERANCE))

    geom = read('LINESTRING(0 0, 10 10)')
    assert(read('LINESTRING(0 0, 10 10)').eql_exact?(geom.convex_hull, TOLERANCE))

    geom = read('POLYGON((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))')
    assert(read('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').eql_exact?(geom.convex_hull, TOLERANCE))
  end

  def test_difference
    comparison_tester(
      :difference,
      'POINT(0 0)',
      'POINT(0 0)',
      'GEOMETRYCOLLECTION EMPTY'
    )

    comparison_tester(
      :difference,
      'POINT(0 0)',
      'POINT(1 0)',
      'POINT (0 0)'
    )

    comparison_tester(
      :difference,
      'LINESTRING(0 0, 10 0)',
      'POINT(5 0)',
      'LINESTRING (0 0, 10 0)'
    )

    comparison_tester(
      :difference,
      'POINT(5 0)',
      'LINESTRING(0 0, 10 0)',
      'GEOMETRYCOLLECTION EMPTY'
    )

    comparison_tester(
      :difference,
      'POINT(5 0)',
      'LINESTRING(0 1, 10 1)',
      'POINT (5 0)'
    )

    comparison_tester(
      :difference,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 -10, 5 10)',
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0))'
    )

    comparison_tester(
      :difference,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 0, 20 0)',
      'LINESTRING (0 0, 5 0)'
    )

    comparison_tester(
      :difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(5 -10, 5 10)',
      'POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0))'
    )

    comparison_tester(
      :difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(10 0, 20 0)',
      'POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0))'
    )

    comparison_tester(
      :difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))',
      'POLYGON ((5 0, 0 0, 0 10, 10 10, 10 5, 5 5, 5 0))'
    )
  end

  def test_sym_difference
    comparison_tester(
      :sym_difference,
      'POINT(0 0)',
      'POINT(0 0)',
      'GEOMETRYCOLLECTION EMPTY'
    )

    comparison_tester(
      :sym_difference,
      'POINT(0 0)',
      'POINT(1 0)',
      'MULTIPOINT (0 0, 1 0)'
    )

    comparison_tester(
      :sym_difference,
      'LINESTRING(0 0, 10 0)',
      'POINT(5 0)',
      'LINESTRING (0 0, 10 0)'
    )

    comparison_tester(
      :sym_difference,
      'POINT(5 0)',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING (0 0, 10 0)'
    )

    comparison_tester(
      :sym_difference,
      'POINT(5 0)',
      'LINESTRING(0 1, 10 1)',
      'GEOMETRYCOLLECTION (POINT (5 0), LINESTRING (0 1, 10 1))'
    )

    comparison_tester(
      :sym_difference,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 -10, 5 10)',
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (5 -10, 5 0), (5 0, 5 10))'
    )

    comparison_tester(
      :sym_difference,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 0, 20 0)',
      'MULTILINESTRING ((0 0, 5 0), (10 0, 20 0))'
    )

    comparison_tester(
      :sym_difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(5 -10, 5 10)',
      'GEOMETRYCOLLECTION (LINESTRING (5 -10, 5 0), POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0)))'
    )

    comparison_tester(
      :sym_difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(10 0, 20 0)',
      'GEOMETRYCOLLECTION (LINESTRING (10 0, 20 0), POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0)))'
    )

    comparison_tester(
      :sym_difference,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))',
      'MULTIPOLYGON (((5 0, 0 0, 0 10, 10 10, 10 5, 5 5, 5 0)), ((5 0, 10 0, 10 5, 15 5, 15 -5, 5 -5, 5 0)))'
    )
  end

  def test_boundary
    self_tester(
      :boundary,
      'POINT(0 0)',
      'GEOMETRYCOLLECTION EMPTY'
    )

    self_tester(
      :boundary,
      'LINESTRING(0 0, 10 10)',
      'MULTIPOINT (0 0, 10 10)'
    )

    self_tester(
      :boundary,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),( 5 5, 5 6, 6 6, 6 5, 5 5))',
      'MULTILINESTRING ((0 0, 10 0, 10 10, 0 10, 0 0), (5 5, 5 6, 6 6, 6 5, 5 5))'
    )
  end

  def test_union
    comparison_tester(
      :union,
      'POINT(0 0)',
      'POINT(0 0)',
      'POINT (0 0)'
    )

    comparison_tester(
      :union,
      'POINT(0 0)',
      'POINT(1 0)',
      'MULTIPOINT (0 0, 1 0)'
    )

    comparison_tester(
      :union,
      'LINESTRING(0 0, 10 0)',
      'POINT(5 0)',
      'LINESTRING (0 0, 10 0)'
    )

    comparison_tester(
      :union,
      'POINT(5 0)',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING (0 0, 10 0)'
    )

    comparison_tester(
      :union,
      'POINT(5 0)',
      'LINESTRING(0 1, 10 1)',
      'GEOMETRYCOLLECTION (POINT (5 0), LINESTRING (0 1, 10 1))'
    )

    comparison_tester(
      :union,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 -10, 5 10)',
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (5 -10, 5 0), (5 0, 5 10))'
    )

    comparison_tester(
      :union,
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 0, 20 0)',
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (10 0, 20 0))'
    )

    comparison_tester(
      :union,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(5 -10, 5 10)',
      'GEOMETRYCOLLECTION (LINESTRING (5 -10, 5 0), POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0)))'
    )

    comparison_tester(
      :union,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(10 0, 20 0)',
      'GEOMETRYCOLLECTION (LINESTRING (10 0, 20 0), POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0)))'
    )

    comparison_tester(
      :union,
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))',
      'POLYGON ((5 0, 0 0, 0 10, 10 10, 10 5, 15 5, 15 -5, 5 -5, 5 0))'
    )
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:union_cascaded)
    def test_union_cascaded
      self_tester(
        :union_cascaded,
        'MULTIPOLYGON(
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11)),
          ((0 0, 11 0, 11 11, 0 11, 0 0))
        ))',
        'POLYGON ((
          1 0, 0 0, 0 1, 0 11, 10 11,
          10 14, 14 14, 14 10, 11 10,
          11 0, 1 0
        ), (11 11, 12 11, 12 12, 11 12, 11 11))'
      )
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:unary_union)
    def test_unary_union
      self_tester(
        :unary_union,
        'MULTIPOLYGON(
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11)),
          ((0 0, 11 0, 11 11, 0 11, 0 0))
        ))',
        'POLYGON ((
          1 0, 0 0, 0 1, 0 11, 10 11,
          10 14, 14 14, 14 10, 11 10,
          11 0, 1 0
        ), (11 11, 12 11, 12 12, 11 12, 11 11))'
      )
    end
  end

  def test_union_without_arguments
    self_tester(
      :union,
      'MULTIPOLYGON(
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)),
        ((0 0, 11 0, 11 11, 0 11, 0 0))
      ))',
      'POLYGON ((
        1 0, 0 0, 0 1, 0 11, 10 11,
        10 14, 14 14, 14 10, 11 10,
        11 0, 1 0
      ), (11 11, 12 11, 12 12, 11 12, 11 11))'
    )
  end

  def test_point_on_surface
    self_tester(
      :point_on_surface,
      'POINT(0 0)',
      'POINT(0 0)'
    )

    self_tester(
      :point_on_surface,
      'LINESTRING(0 0, 5 5, 10 10)',
      'POINT (5 5)'
    )

    self_tester(
      :point_on_surface,
      'POLYGON((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))',
      'POINT (2.5 5)'
    )
  end

  def test_centroid
    self_tester(
      :centroid,
      'POINT(0 0)',
      'POINT (0 0)'
    )

    self_tester(
      :centroid,
      'LINESTRING(0 0, 10 10)',
      'POINT (5 5)'
    )

    self_tester(
      :centroid,
      'POLYGON((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))',
      'POINT (5 3.888888888888888888)'
    )
  end

  def test_envelope
    self_tester(
      :envelope,
      'POINT(0 0)',
      'POINT (0 0)'
    )

    self_tester(
      :envelope,
      'LINESTRING(0 0, 10 10)',
      'POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))'
    )
  end

  def test_relate
    tester = lambda { |expected, geom_a, geom_b|
      assert_equal(expected, geom_a.relate(geom_b))
    }

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(0 0)')
    tester['0FFFFFFF2', geom_a, geom_b]

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(1 0)')
    tester['FF0FFF0F2', geom_a, geom_b]

    geom_a = read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')
    geom_b = read('POINT(1 0)')
    tester['FF20F1FF2', geom_a, geom_b]
  end

  def test_relate_pattern
    tester = lambda { |pattern, geom_a, geom_b, expected|
      assert_equal(expected, geom_a.relate_pattern(geom_b, pattern))
    }

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(0 0)')
    tester['0FFFFFFF2', geom_a, geom_b, true]
    tester['0*******T', geom_a, geom_b, true]
    tester['0*******1', geom_a, geom_b, false]

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(1 0)')
    tester['FF0FFF0F2', geom_a, geom_b, true]
    tester['F*******2', geom_a, geom_b, true]
    tester['T*******2', geom_a, geom_b, false]

    geom_a = read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')
    geom_b = read('POINT(1 0)')
    tester['FF20F1FF2', geom_a, geom_b, true]
    tester['F****T**T', geom_a, geom_b, true]
    tester['T*******2', geom_a, geom_b, false]
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:relate_boundary_node_rule)
    def test_relate_boundary_node_rule
      geom_a = read('LINESTRING(0 0, 2 4, 5 5, 0 0)')
      geom_b = read('POINT(0 0)')

      ret = geom_a.relate_boundary_node_rule(geom_b, :ogc)
      assert_equal('0F1FFFFF2', ret)

      ret = geom_a.relate_boundary_node_rule(geom_b, :endpoint)
      assert_equal('FF10FFFF2', ret)

      assert_raise(TypeError) do
        geom_a.relate_boundary_node_rule(geom_b, :gibberish)
      end
    end
  end

  def test_line_merge
    self_tester(
      :line_merge,
      'MULTILINESTRING(
        (0 0, 10 10),
        (10 10, 10 0),
        (5 0, 10 0),
        (5 -5, 5 0)
            )',
      'LINESTRING (0 0, 10 10, 10 0, 5 0, 5 -5)'
    )
  end

  def test_simplify
    self_tester(
      [ :simplify, 2 ],
      'LINESTRING(0 0, 3 4, 5 10, 10 0, 10 9, 5 11, 0 9)',
      'LINESTRING (0 0, 5 10, 10 0, 10 9, 0 9)'
    )
  end

  def test_topology_preserve_simplify
    self_tester(
      [ :topology_preserve_simplify, 2 ],
      'LINESTRING(0 0, 3 4, 5 10, 10 0, 10 9, 5 11, 0 9)',
      'LINESTRING (0 0, 5 10, 10 0, 10 9, 5 11, 0 9)'
    )
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:extract_unique_points)
    def test_extract_unique_points
      writer.rounding_precision = 0

      geom = read('GEOMETRYCOLLECTION (
        MULTIPOLYGON (
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11))
        ),
        POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
        MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
        LINESTRING (0 0, 2 3),
        MULTIPOINT (0 0, 2 3),
        POINT (9 0),
        POINT(1 0)),
        LINESTRING EMPTY
      ')

      assert_equal(
        'MULTIPOINT (0 0, 1 0, 1 1, 0 1, 10 10, 10 14, 14 14, 14 10, 11 11, 11 12, 12 12, 12 11, 2 3, 3 4, 9 0)',
        write(geom.extract_unique_points)
      )
    end
  end

  def test_relationships
    tester = lambda { |geom_a, geom_b, tests|
      tests.each do |test|
        expected, method, args = test
        if ENV['FORCE_TESTS'] || geom_a.respond_to?(method)
          value = geom_a.send(method, *([ geom_b ] + Array(args)))
          assert_equal(expected, value)
        end
      end
    }

    tester[read('POINT(0 0)'), read('POINT(0 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [true, :contains?],
      [false, :overlaps?],
      [true, :eql?],
      [true, :eql_exact?, TOLERANCE],
      [true, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POINT(0 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [true, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POINT(5 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('LINESTRING(5 -5, 5 5)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [true, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('LINESTRING(5 0, 15 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [true, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('LINESTRING(0 0, 5 0, 10 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [true, :contains?],
      [false, :overlaps?],
      [true, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [true, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'), read('POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [true, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'), read('POINT(15 15)'), [
      [true, :disjoint?],
      [false, :touches?],
      [false, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]
  end

  def test_empty
    assert(!read('POINT(0 0)').empty?)
    assert(read('POINT EMPTY').empty?)
    assert(!read('LINESTRING(0 0, 10 0)').empty?)
    assert(read('LINESTRING EMPTY').empty?)
    assert(!read('POLYGON((0 0, 10 0, 10 10, 0 0))').empty?)
    assert(read('POLYGON EMPTY').empty?)
    assert(!read('GEOMETRYCOLLECTION(POINT(0 0))').empty?)
    assert(read('GEOMETRYCOLLECTION EMPTY').empty?)
  end

  def test_valid
    assert(read('POINT(0 0)').valid?)
    assert(!read('POINT(0 NaN)').valid?)
    assert(!read('POINT(0 nan)').valid?)
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:valid_reason)
    def test_valid_reason
      assert_equal("Valid Geometry", read('POINT(0 0)').valid_reason)
      assert_equal("Invalid Coordinate[0 nan]", read('POINT(0 NaN)').valid_reason)
      assert_equal("Invalid Coordinate[0 nan]", read('POINT(0 nan)').valid_reason)
      assert_equal("Self-intersection[2.5 5]", read('POLYGON((0 0, 0 5, 5 5, 5 10, 0 0))').valid_reason)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:valid_detail)
    def test_valid_detail
      tester = lambda { |detail, location, geom, flags|
        ret = read(geom).valid_detail(flags)
        assert_equal(detail, ret[:detail])
        assert_equal(location, write(ret[:location]))
      }

      writer.rounding_precision = 0

      assert_nil(read('POINT(0 0)').valid_detail)
      tester["Invalid Coordinate", 'POINT (0 nan)', 'POINT(0 NaN)', 0]
      tester["Self-intersection", 'POINT (2 5)', 'POLYGON((0 0, 0 5, 5 5, 5 10, 0 0))', 0]

      tester["Ring Self-intersection", 'POINT (0 0)', 'POLYGON((0 0, -10 10, 10 10, 0 0, 4 5, -4 5, 0 0)))', 0]

      assert_nil(read('POLYGON((0 0, -10 10, 10 10, 0 0, 4 5, -4 5, 0 0)))').valid_detail(
        :allow_selftouching_ring_forming_hole
      ))
    end
  end

  def test_simple
    assert(read('POINT(0 0)').simple?)
    assert(read('LINESTRING(0 0, 10 0)').simple?)
    assert(!read('LINESTRING(0 0, 10 0, 5 5, 5 -5)').simple?)
  end

  def test_ring
    assert(!read('POINT(0 0)').ring?)
    assert(!read('LINESTRING(0 0, 10 0, 5 5, 5 -5)').ring?)
    assert(read('LINESTRING(0 0, 10 0, 5 5, 0 0)').ring?)
  end

  def test_has_z
    assert(!read('POINT(0 0)').has_z?)
    assert(read('POINT(0 0 0)').has_z?)
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:closed?)
    def test_closed
      assert(read('LINESTRING(0 0, 1 1, 2 2, 0 0)').closed?)
      assert(!read('LINESTRING(0 0, 1 1, 2 2)').closed?)
      assert(read('LINEARRING(0 0, 1 1, 2 2, 0 0)').closed?)
    end
  end

  def test_num_geometries
    tester = lambda { |expected, g|
      geom = read(g)
      assert_equal(expected, geom.num_geometries)
    }

    tester[1, 'POINT(0 0)']
    tester[2, 'MULTIPOINT (0 1, 2 3)']
    tester[1, 'LINESTRING (0 0, 2 3)']
    tester[2, 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))']
    tester[1, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
    tester[2, 'MULTIPOLYGON(
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      ((10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11)))'
    ]
    tester[6, 'GEOMETRYCOLLECTION (
      MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      ),
      POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
      MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
      LINESTRING (0 0, 2 3),
      MULTIPOINT (0 0, 2 3),
      POINT (9 0))'
    ]
  end

  # get_geometry_n is segfaulting in the binary GEOS build
  if defined?(Geos::FFIGeos)
    def test_get_geometry_n
      tester = lambda { |expected, g, n|
        geom = read(g)
        result = geom.get_geometry_n(n)

        if expected.nil?
          assert_nil(result)
        else
          assert(result.eql_exact?(read(expected), TOLERANCE))
        end
      }

      tester['POINT(0 1)', 'MULTIPOINT (0 1, 2 3)', 0]
      tester['POINT(2 3)', 'MULTIPOINT (0 1, 2 3)', 1]
      tester[nil, 'MULTIPOINT (0 1, 2 3)', 2]
    end
  end

  def test_num_interior_rings
    tester = lambda { |expected, g|
      geom = read(g)
      assert_equal(expected, geom.num_interior_rings)
    }

    tester[0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
    tester[1, 'POLYGON (
      (10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11)
    )']
    tester[2, 'POLYGON (
      (10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11),
      (13 11, 13 12, 13.5 12, 13.5 11, 13 11))'
    ]

    assert_raise(NoMethodError) do
      tester[0, 'POINT (0 0)']
    end
  end

  def test_interior_ring_n
    tester = lambda { |expected, g, n|
      geom = read(g)
      result = geom.interior_ring_n(n)

      if expected.nil?
        assert_nil(result)
      else
        assert(result.eql_exact?(read(expected), TOLERANCE))
      end
    }

    tester[
      'LINEARRING(11 11, 11 12, 12 12, 12 11, 11 11)',
      'POLYGON(
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )',
      0
    ]

    tester[
      'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )',
      0
    ]

    tester[
      'LINEARRING (13 11, 13 12, 13.5 12, 13.5 11, 13 11)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )',
      1
    ]

    assert_raise(RuntimeError) do
      tester[
        nil,
        'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))',
        0
      ]
    end

    assert_raise(NoMethodError) do
      tester[
        nil,
        'POINT (0 0)',
        0
      ]
    end
  end

  def test_exterior_ring
    tester = lambda { |expected, g|
      geom = read(g)
      result = geom.exterior_ring

      if expected.nil?
        assert_nil(result)
      else
        assert(result.eql_exact?(read(expected), TOLERANCE))
      end
    }

    tester[
      'LINEARRING (10 10, 10 14, 14 14, 14 10, 10 10)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )'
    ]

    assert_raise(NoMethodError) do
      tester[
        nil,
        'POINT (0 0)'
      ]
    end
  end

  def test_interior_rings
    tester = lambda { |expected, g|
      geom = read(g)
      result = geom.interior_rings

      if expected.nil?
        assert_nil(result)
      else
        assert_equal(expected, result.collect { |r| write(r) } )
      end
    }

    writer.trim = true

    tester[
      [ 'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)' ],
      'POLYGON(
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )'
    ]

    tester[
      [
        'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)',
        'LINEARRING (13 11, 13 12, 13.5 12, 13.5 11, 13 11)'
      ],
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )'
    ]
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:num_coordinates)
    def test_num_coordinates
      tester = lambda { |expected, g|
        geom = read(g)
        result = geom.num_coordinates

        assert_equal(expected, result)
      }

      tester[1, 'POINT(0 0)']
      tester[2, 'MULTIPOINT (0 1, 2 3)']
      tester[2, 'LINESTRING (0 0, 2 3)']
      tester[4, 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))']
      tester[5, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
      tester[15, 'MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      )']
      tester[29, 'GEOMETRYCOLLECTION (
        MULTIPOLYGON (
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11))
        ),
        POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
        MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
        LINESTRING (0 0, 2 3),
        MULTIPOINT ((0 0), (2 3)),
        POINT (9 0)
      )']
    end
  end

  def test_coord_seq
    tester = lambda { |expected, g|
      geom = read(g)
      cs = geom.coord_seq
      expected.each_with_index do |c, i|
        assert_equal(c[0], cs.get_x(i))
        assert_equal(c[1], cs.get_y(i))
      end
    }

    tester[[[0, 0]], 'POINT(0 0)']
    tester[[[0, 0], [2, 3]], 'LINESTRING (0 0, 2 3)']
    tester[[[0, 0], [0, 5], [5, 5], [5, 0], [0, 0]], 'LINEARRING(0 0, 0 5, 5 5, 5 0, 0 0)']
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:num_points)
    def test_num_points
      assert_equal(4, read('LINESTRING (0 0, 1 0, 1 1, 0 1)').num_points)

      assert_raise(NoMethodError) do
        read('POINT (0 0)').num_points
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Point.method_defined?(:get_x)
    def test_get_x_and_get_y
      geom = read('POINT (1 2)')
      assert_equal(1, geom.get_x)
      assert_equal(2, geom.get_y)

      assert_equal(1, geom.x)
      assert_equal(2, geom.y)

      assert_raise(NoMethodError) do
        read('LINESTRING (0 0, 1 1)').get_x
      end
    end
  end

  def test_dimensions
    tester = lambda { |expected, g|
      geom = read(g)
      result = geom.dimensions

      assert_equal(expected, result)
    }

    types = {
      :dontcare => -3,
      :non_empty => -2,
      :empty => -1,
      :point => 0,
      :curve => 1,
      :surface => 2
    }

    tester[types[:point], 'POINT(0 0)']
    tester[types[:point], 'MULTIPOINT (0 1, 2 3)']
    tester[types[:curve], 'LINESTRING (0 0, 2 3)']
    tester[types[:curve], 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))']
    tester[types[:surface], 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
    tester[types[:surface], 'MULTIPOLYGON (
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      ((10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11)))'
    ]
    tester[types[:surface], 'GEOMETRYCOLLECTION (
      MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      ),
      POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
      MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
      LINESTRING (0 0, 2 3),
      MULTIPOINT (0 0, 2 3),
      POINT (9 0)
    )']
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:project)
    def test_project_and_project_normalized
      geom_a = read('POINT(1 2)')
      geom_b = read('POINT(3 4)')

      # The method only accept lineal geometries
      assert_raise(RuntimeError) do
        geom_a.project(geom_b)
      end

      geom_a = read('LINESTRING(0 0, 10 0)')
      geom_b = read('POINT(0 0)')
      assert_equal(0, geom_a.project(geom_b))
      assert_equal(0, geom_a.project(geom_b, true))

      geom_b = read('POINT(10 0)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(1, geom_a.project(geom_b, true))

      geom_b = read('POINT(5 0)')
      assert_equal(5, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))

      geom_a = read('MULTILINESTRING((0 0, 10 0),(20 10, 20 20))')
      geom_b = read('POINT(20 0)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))

      geom_b = read('POINT(20 5)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:interpolate)
    def test_interpolate
      tester = lambda { |expected, g, d, normalize|
        geom = read(g)
        assert_equal(expected, write(geom.interpolate(d, normalize)))
      }

      writer.trim = true

      tester['POINT (0 0)', 'LINESTRING(0 0, 10 0)', 0, false]
      tester['POINT (0 0)', 'LINESTRING(0 0, 10 0)', 0, true]

      tester['POINT (5 0)', 'LINESTRING(0 0, 10 0)', 5, false]
      tester['POINT (5 0)', 'LINESTRING(0 0, 10 0)', 0.5, true]

      tester['POINT (10 0)', 'LINESTRING(0 0, 10 0)', 20, false]
      tester['POINT (10 0)', 'LINESTRING(0 0, 10 0)', 2, true]

      assert_raise(RuntimeError) do
        read('POINT(1 2)').interpolate(0)
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:point_n)
    def test_point_n
      writer.rounding_precision = 0

      tester = lambda { |expected, geom, n|
        assert_equal(expected, write(geom.point_n(n)))
      }

      geom = read('LINESTRING (10 10, 10 14, 14 14, 14 10)')
      tester['POINT (10 10)', geom, 0]
      tester['POINT (10 14)', geom, 1]
      tester['POINT (14 14)', geom, 2]
      tester['POINT (14 10)', geom, 3]

      assert_raise(RuntimeError) do
        tester['POINT (0 0)', geom, 4]
      end

      geom = read('LINEARRING (11 11, 11 12, 12 11, 11 11)')
      tester['POINT (11 11)', geom, 0]
      tester['POINT (11 12)', geom, 1]
      tester['POINT (12 11)', geom, 2]
      tester['POINT (11 11)', geom, 3]

      assert_raise(NoMethodError) do
        tester[nil, read('POINT (0 0)'), 0]
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:start_point)
    def test_start_and_end_points
      writer.rounding_precision = 0

      tester = lambda { |expected, method, geom|
        assert_equal(expected, write(geom.send(method)))
      }

      geom = read('LINESTRING (10 10, 10 14, 14 14, 14 10)')
      tester['POINT (10 10)', :start_point, geom]
      tester['POINT (14 10)', :end_point, geom]

      geom = read('LINEARRING (11 11, 11 12, 12 11, 11 11)')
      tester['POINT (11 11)', :start_point, geom]
      tester['POINT (11 11)', :end_point, geom]
    end
  end

  def test_area
    tester = lambda { |expected, g|
      assert_in_delta(expected, read(g).area, TOLERANCE)
    }

    tester[1.0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
    tester[0.0, 'POINT (0 0)']
    tester[0.0, 'LINESTRING (0 0 , 10 0)']
  end

  def test_length
    tester = lambda { |expected, g|
      assert_in_delta(expected, read(g).length, TOLERANCE)
    }

    tester[4.0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))']
    tester[0.0, 'POINT (0 0)']
    tester[10.0, 'LINESTRING (0 0 , 10 0)']
  end

  def test_distance
    tester = lambda { |expected, g1, g2|
      geom_1 = read(g1)
      geom_2 = read(g2)
      assert_in_delta(expected, geom_1.distance(geom_2), TOLERANCE)
    }

    g = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'
    tester[0.0, g, 'POINT(0.5 0.5)']
    tester[1.0, g, 'POINT (-1 0)']
    tester[2.0, g, 'LINESTRING (3 0 , 10 0)']
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:hausdorff_distance)
    def test_hausdorff_distance
      tester = lambda { |expected, g1, g2|
        geom_1 = read(g1)
        geom_2 = read(g2)
        assert_in_delta(expected, geom_1.hausdorff_distance(geom_2), TOLERANCE)
      }

      geom_a = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'

      tester[10.0498756211209, geom_a, 'POINT(0 10)']
      tester[2.23606797749979, geom_a, 'POINT(-1 0)']
      tester[9.0, geom_a, 'LINESTRING (3 0 , 10 0)']
    end

    def test_hausdorff_distance_with_densify_fract
      tester = lambda { |expected, g1, g2|
        geom_1 = read(g1)
        geom_2 = read(g2)
        assert_in_delta(expected, geom_1.hausdorff_distance(geom_2, 0.001), TOLERANCE)
      }

      geom_a = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'

      tester[10.0498756211209, geom_a, 'POINT(0 10)']
      tester[2.23606797749979, geom_a, 'POINT(-1 0)']
      tester[9.0, geom_a, 'LINESTRING (3 0 , 10 0)']
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:snap)
    def test_snap
      tester = lambda { |expected, g1, g2, tolerance|
        geom_a = read(g1)
        geom_b = read(g2)
        assert(read(expected).eql_exact?(geom_a.snap(geom_b, tolerance), TOLERANCE))
      }

      writer.trim = true

      geom = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'
      tester['POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))', geom, 'POINT(0.1 0)', 0]
      tester['POLYGON ((0.1 0, 1 0, 1 1, 0 1, 0.1 0))', geom, 'POINT(0.1 0)', 0.5]
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize)
    def test_polygonize
      writer.rounding_precision = 0

      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )'
      )

      polygonized = geom_a.polygonize
      assert_equal(2, polygonized.length)
      assert_equal(
        'POLYGON ((185 221, 88 275, 180 316, 292 281, 185 221))',
        write(polygonized[0])
      )
      assert_equal(
        'POLYGON ((189 98, 83 187, 185 221, 325 168, 189 98))',
        write(polygonized[1])
      )
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize_cut_edges)
    def test_polygonize_cut_edges
      writer.rounding_precision = 0

      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )'
      )

      cut_edges = geom_a.polygonize_cut_edges
      assert_equal(0, cut_edges.length)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize_full)
    def test_polygonize_full
      writer.rounding_precision = 0

      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )')

      polygonized = geom_a.polygonize_full

      assert(polygonized[:rings].is_a?(Array))
      assert(polygonized[:cuts].is_a?(Array))
      assert(polygonized[:dangles].is_a?(Array))
      assert(polygonized[:invalid_rings].is_a?(Array))

      assert_equal(2, polygonized[:rings].length)
      assert_equal(0, polygonized[:cuts].length)
      assert_equal(2, polygonized[:dangles].length)
      assert_equal(0, polygonized[:invalid_rings].length)

      assert_equal(
        'POLYGON ((185 221, 88 275, 180 316, 292 281, 185 221))',
        write(polygonized[:rings][0])
      )

      assert_equal(
        'POLYGON ((189 98, 83 187, 185 221, 325 168, 189 98))',
        write(polygonized[:rings][1])
      )

      assert_equal(
        'LINESTRING (185 221, 100 100)',
        write(polygonized[:dangles][0])
      )

      assert_equal(
        'LINESTRING (0 0, 10 10)',
        write(polygonized[:dangles][1])
      )

      geom_b = geom_a.union(read('POINT(0 0)'))
      polygonized = geom_b.polygonize_full

      assert_equal(2, polygonized[:dangles].length)
      assert_equal(0, polygonized[:invalid_rings].length)

      assert_equal(
        'LINESTRING (132 146, 100 100)',
        write(polygonized[:dangles][0])
      )

      assert_equal(
        'LINESTRING (0 0, 10 10)',
        write(polygonized[:dangles][1])
      )
    end

    def test_polygonize_with_bad_arguments
      assert_raise(ArgumentError) do
        geom = read('POINT(0 0)')

        geom.polygonize(geom, 'gibberish')
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:shared_paths)
    def test_shared_paths
      writer.rounding_precision = 0

      geom_a = read('LINESTRING(0 0, 50 0)')
      geom_b = read('MULTILINESTRING((5 0, 15 0),(40 0, 30 0))')

      paths = geom_a.shared_paths(geom_b)
      assert_equal(2, paths.length)
      assert_equal(
        'MULTILINESTRING ((5 0, 15 0))',
        write(paths[0])
      )
      assert_equal(
        'MULTILINESTRING ((30 0, 40 0))',
        write(paths[1])
      )
    end
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:select)
    def test_line_string_enumerable
      @writer.trim = true
      geom = read('LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2)')

      assert_equal(2, geom.select { |point| point == read('POINT(2 2)') }.length)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:detect)
    def test_geometry_collection_enumerable
      @writer.trim = true
      geom = read('GEOMETRYCOLLECTION(
        LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2),
        POINT(10 20),
        POLYGON((0 0, 0 5, 5 5, 5 0, 0 0)),
        POINT(10 20)
      )')

      assert_equal(2, geom.select { |point| point == read('POINT(10 20)') }.length)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:[])
    def test_line_string_array
      @writer.trim = true
      geom = read('LINESTRING(0 0, 1 1, 2 2, 3 3, 4 4)')

      assert_equal('POINT (0 0)', write(geom[0]))
      assert_equal('POINT (4 4)', write(geom[-1]))

      assert_equal([
        'POINT (0 0)',
        'POINT (1 1)'
      ], geom[0, 2].collect { |g| write(g) })

      assert_equal(nil, geom[0, -1])
      assert_equal([], geom[-1, 0])
      assert_equal([
        'POINT (1 1)',
        'POINT (2 2)'
      ], geom[1..2].collect { |g| write(g) })
    end
  end

  if ENV['FORCE_TESTS'] || Geos::GeometryCollection.method_defined?(:[])
    def test_geometry_collection_array
      @writer.trim = true
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

  def test_clone
    geom_a = read('POINT(0 0)')
    geom_b = geom_a.clone

    assert(geom_a.eql?(geom_b))
  end

  def test_clone_srid
    srid = 4326
    geom_a = read('POINT(0 0)')
    geom_a.srid = srid
    geom_b = geom_a.clone

    assert(geom_a.eql?(geom_b))
    assert_equal(srid, geom_b.srid)
  end

  def test_dup
    geom_a = read('POINT(0 0)')
    geom_b = geom_a.dup

    assert(geom_a.eql?(geom_b))
  end

  def test_dup_srid
    srid = 4326
    geom_a = read('POINT(0 0)')
    geom_a.srid = srid
    geom_b = geom_a.dup
    assert(geom_a.eql?(geom_b))
    assert_equal(srid, geom_b.srid)
  end

  def test_geometry_collection_enumerator
    geom = read('GEOMETRYCOLLECTION(POINT(0 0))')
    assert_kind_of(Enumerable, geom.each)
    assert_kind_of(Enumerable, geom.to_enum)
    assert_equal(geom, geom.each {})
  end

  def test_line_string_enumerator
    geom = read('LINESTRING(0 0, 10 10))')
    assert_kind_of(Enumerable, geom.each)
    assert_kind_of(Enumerable, geom.to_enum)
    assert_equal(geom, geom.each {})
  end
end
