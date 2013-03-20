# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class LineStringTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_default_srid
    geom = read('LINESTRING (0 0, 10 10)')
    assert_equal(0, geom.srid)
  end

  def test_setting_srid_manually
    geom = read('LINESTRING (0 0, 10 10)')
    geom.srid = 4326
    assert_equal(4326, geom.srid)
  end

  def test_dimensions
    geom = read('LINESTRING (0 0, 10 10)')
    assert_equal(1, geom.dimensions)

    geom = read('LINESTRING (0 0 0, 10 10 10)')
    assert_equal(1, geom.dimensions)
  end

  def test_num_geometries
    geom = read('LINESTRING (0 0, 10 10)')
    assert_equal(1, geom.num_geometries)
  end

  def test_line_string_array
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:[])

    writer.trim = true
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

  def test_line_string_enumerable
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:select)

    writer.trim = true
    geom = read('LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2)')

    assert_equal(2, geom.select { |point| point == read('POINT(2 2)') }.length)
  end

  def test_offset_curve
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:offset_curve)

    tester = lambda { |expected, g, width, style|
      geom = read(g)
      buffered = geom.offset_curve(width, style)

      assert_equal(expected, write(buffered))
    }

    writer.rounding_precision = 0

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

  def test_closed
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:closed?)

    assert_geom_closed(read('LINESTRING(0 0, 1 1, 2 2, 0 0)'))
    refute_geom_closed(read('LINESTRING(0 0, 1 1, 2 2)'))
    assert_geom_closed(read('LINEARRING(0 0, 1 1, 2 2, 0 0)'))
  end

  def test_num_points
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:num_points)

    assert_equal(4, read('LINESTRING (0 0, 1 0, 1 1, 0 1)').num_points)

    assert_raises(NoMethodError) do
      read('POINT (0 0)').num_points
    end
  end

  def test_point_n
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:point_n)

    writer.rounding_precision = 0

    tester = lambda { |expected, geom, n|
      assert_equal(expected, write(geom.point_n(n)))
    }

    geom = read('LINESTRING (10 10, 10 14, 14 14, 14 10)')
    tester['POINT (10 10)', geom, 0]
    tester['POINT (10 14)', geom, 1]
    tester['POINT (14 14)', geom, 2]
    tester['POINT (14 10)', geom, 3]

    assert_raises(RuntimeError) do
      tester['POINT (0 0)', geom, 4]
    end

    geom = read('LINEARRING (11 11, 11 12, 12 11, 11 11)')
    tester['POINT (11 11)', geom, 0]
    tester['POINT (11 12)', geom, 1]
    tester['POINT (12 11)', geom, 2]
    tester['POINT (11 11)', geom, 3]

    assert_raises(NoMethodError) do
      tester[nil, read('POINT (0 0)'), 0]
    end
  end
end
