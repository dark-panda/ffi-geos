# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class LineStringTests < Minitest::Test
  include TestHelper

  def setup
    super
    writer.trim = true
  end

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

    geom = read('LINESTRING(0 0, 1 1, 2 2, 3 3, 10 0, 2 2)')

    assert_equal(2, geom.select { |point| point == read('POINT(2 2)') }.length)
  end

  def test_offset_curve
    skip unless ENV['FORCE_TESTS'] || Geos::LineString.method_defined?(:offset_curve)

    # straight left
    simple_tester(
      :offset_curve,
      'LINESTRING (0 2, 10 2)',
      'LINESTRING (0 0, 10 0)',
      2, {
        :quad_segs => 0,
        :join => :round,
        :mitre_limit => 2
      }
    )

    # straight right
    simple_tester(
      :offset_curve,
      'LINESTRING (10 -2, 0 -2)',
      'LINESTRING (0 0, 10 0)',
      -2, {
        :quad_segs => 0,
        :join => :round,
        :mitre_limit => 2
      }
    )

    # outside curve
    simple_tester(
      :offset_curve,
      'LINESTRING (12 10, 12 0, 10 -2, 0 -2)',
      'LINESTRING (0 0, 10 0, 10 10)',
      -2, {
        :quad_segs => 1,
        :join => :round,
        :mitre_limit => 2
      }
    )

    # inside curve
    simple_tester(
      :offset_curve,
      'LINESTRING (0 2, 8 2, 8 10)',
      'LINESTRING (0 0, 10 0, 10 10)',
      2, {
        :quad_segs => 1,
        :join => :round,
        :mitre_limit => 2
      }
    )
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

    geom = read('LINESTRING (10 10, 10 14, 14 14, 14 10)')
    simple_tester(:point_n, 'POINT (10 10)', geom, 0)
    simple_tester(:point_n, 'POINT (10 14)', geom, 1)
    simple_tester(:point_n, 'POINT (14 14)', geom, 2)
    simple_tester(:point_n, 'POINT (14 10)', geom, 3)

    assert_raises(Geos::IndexBoundsError) do
      geom.point_n(4)
    end

    geom = read('LINEARRING (11 11, 11 12, 12 11, 11 11)')
    simple_tester(:point_n, 'POINT (11 11)', geom, 0)
    simple_tester(:point_n, 'POINT (11 12)', geom, 1)
    simple_tester(:point_n, 'POINT (12 11)', geom, 2)
    simple_tester(:point_n, 'POINT (11 11)', geom, 3)

    assert_raises(NoMethodError) do
      read('POINT (0 0)').point_n(0)
    end
  end

  def test_to_linear_ring
    simple_tester(:to_linear_ring, 'LINEARRING (0 0, 0 5, 5 5, 5 0, 0 0)', 'LINESTRING (0 0, 0 5, 5 5, 5 0, 0 0)')
    simple_tester(:to_linear_ring, 'LINEARRING (0 0, 0 5, 5 5, 5 0, 0 0)', 'LINESTRING (0 0, 0 5, 5 5, 5 0)')

    writer.output_dimensions = 3
    simple_tester(:to_linear_ring, 'LINEARRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0)', 'LINESTRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0)')
    simple_tester(:to_linear_ring, 'LINEARRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0)', 'LINESTRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0)')
  end

  def test_to_linear_ring_with_srid
    wkt = 'LINESTRING (0 0, 5 0, 5 5, 0 5, 0 0)'
    expected = 'LINEARRING (0 0, 5 0, 5 5, 0 5, 0 0)'

    srid_copy_tester(:to_linear_ring, expected, 0, :zero, wkt)
    srid_copy_tester(:to_linear_ring, expected, 4326, :lenient, wkt)
    srid_copy_tester(:to_linear_ring,  expected, 4326, :strict, wkt)
  end

  def test_to_polygon
    simple_tester(:to_polygon, 'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', 'LINESTRING (0 0, 0 5, 5 5, 5 0, 0 0)')
    simple_tester(:to_polygon, 'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', 'LINESTRING (0 0, 0 5, 5 5, 5 0)')

    writer.output_dimensions = 3
    simple_tester(:to_polygon, 'POLYGON Z ((0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0))', 'LINESTRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0)')
    simple_tester(:to_polygon, 'POLYGON Z ((0 0 0, 0 5 0, 5 5 0, 5 0 0, 0 0 0))', 'LINESTRING Z (0 0 0, 0 5 0, 5 5 0, 5 0 0)')
  end

  def test_to_polygon_with_srid
    wkt = 'LINESTRING (0 0, 5 0, 5 5, 0 5, 0 0)'
    expected = 'POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))'

    srid_copy_tester(:to_polygon, expected, 0, :zero, wkt)
    srid_copy_tester(:to_polygon, expected, 4326, :lenient, wkt)
    srid_copy_tester(:to_polygon,  expected, 4326, :strict, wkt)
  end
end
