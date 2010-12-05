
$: << File.dirname(__FILE__)
require 'test_helper'

class WkbReaderTests < Test::Unit::TestCase
  include TestHelper

  def setup
    @wkb_reader = Geos::WkbReader.new
    @writer = Geos::WktWriter.new
    @reader = Geos::WktReader.new
  end

  def wkb_tester(expected, g, type_id, geom_type, klass, srid)
    geom = @wkb_reader.read_hex(g)
    assert(geom)
    assert_equal(type_id, geom.type_id)
    assert_equal(geom_type, geom.geom_type)
    assert(geom.is_a?(klass))
    assert(read(expected).eql_exact?(geom, TOLERANCE))
    assert_equal(srid, geom.srid)
  end

  def test_2d_little_endian
    wkb_tester(
      'POINT(6 7)',
      '010100000000000000000018400000000000001C40',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      0
    )
  end

  def test_2d_big_endian
    wkb_tester(
      'POINT (6 7)',
      '00000000014018000000000000401C000000000000',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      0
    )
  end

  def test_2d_little_endian_srid
    wkb_tester(
      'POINT (6 7)',
      '01010000202B00000000000000000018400000000000001C40',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      43
    )
  end

  def test_2d_big_endian_srid
    wkb_tester(
      'POINT (6 7)',
      '00200000010000002B4018000000000000401C000000000000',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      43
    )
  end

  def test_3d_little_endian
    wkb_tester(
      'POINT Z (6 7 8)',
      '010100008000000000000018400000000000001C400000000000002040',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      0
    )
  end

  def test_3d_big_endian
    wkb_tester(
      'POINT Z (6 7 8)',
      '00800000014018000000000000401C0000000000004020000000000000',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      0
    )
  end

  def test_3d_big_endian_srid
    wkb_tester(
      'POINT Z (6 7 8)',
      '00A0000001000000354018000000000000401C0000000000004020000000000000',
      Geos::GEOS_POINT,
      'Point',
      Geos::Point,
      53
    )
  end
end
