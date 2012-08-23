# frozen_string_literal: true

require 'test_helper'

class PolygonTests < Minitest::Test
  include TestHelper

  def setup
    super
    writer.trim = true
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

  def test_x_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(8, geom.x_max)
  end

  def test_x_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(-10, geom.x_min)
  end

  def test_y_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(9, geom.y_max)
  end

  def test_y_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.y_min)
  end

  def test_z_max
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.z_min)

    geom = read('POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0))')
    assert_equal(4, geom.z_max)
  end

  def test_z_min
    geom = read('POLYGON ((0 0, 5 0, 8 9, -10 5, 0 0))')
    assert_equal(0, geom.z_min)

    geom = read('POLYGON Z ((0 0 0, 5 0 3, 8 9 4, -10 5 3, 0 0 0))')
    assert_equal(0, geom.z_min)
  end

  def test_snap_to_grid
    wkt = 'POLYGON ((-10.12 0, -10.12 5, -10.12 5, -10.12 6, -10.12 6, -10.12 6, -10.12 7, -10.12 7, -10.12 7, -10.12 8, -10.12 8, -9 8, -9 9, -10.12 0))'
    expected = 'POLYGON ((-10 0, -10 5, -10 6, -10 7, -10 8, -9 8, -9 9, -10 0))'

    simple_bang_tester(:snap_to_grid, expected, wkt, 1)
  end

  def test_snap_to_grid_with_illegal_result
    assert_raises(Geos::InvalidGeometryError) do
      read('POLYGON ((1 1, 10 10, 10 10, 1 1))').
        snap_to_grid
    end
  end

  def test_snap_to_grid_empty
    assert(read('POLYGON EMPTY').snap_to_grid!.empty?, 'Expected an empty Polygon')
  end

  def test_snap_to_grid_collapse_holes
    wkt = 'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0), (2.6 2.6, 2.7 2.6, 2.7 2.7, 2.6 2.7, 2.6 2.6))'

    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(read(wkt).snap_to_grid(1)))
  end

  def test_snap_to_grid_with_srid
    wkt = 'POLYGON ((0.1 0.1, 0.1 5.1, 5.1 5.1, 5.1 0.1, 0.1 0.1))'
    expected = 'POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))'

    srid_copy_tester(:snap_to_grid, expected, 0, :zero, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :lenient, wkt, 1)
    srid_copy_tester(:snap_to_grid, expected, 4326, :strict, wkt, 1)
  end
end
