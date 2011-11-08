
$: << File.dirname(__FILE__)
require 'test_helper'

class UtilsTests < Test::Unit::TestCase
  include TestHelper

  if defined?(Geos::Utils)
    if Geos::Utils.respond_to?(:orientation_index)
      def test_orientation_index
        assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 5, 0))
        assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 10, 0))
        assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 0, 0))
        assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, -5, 0))
        assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 20, 0))
        assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 6))
        assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 20))
        assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 3))
        assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, -2))
        assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 1000000, 1000001))
        assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 1000000,  999999))
      end
    end

    if Geos::Utils.respond_to?(:relate_match)
      def test_relate_match
        assert(Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFF2'))
        assert(Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFF*'))
        assert(Geos::Utils.relate_match('0FFFFFFF2', 'TFFFFFFF2'))
        assert(!Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFFF'))
      end
    end
  end

  def create_method_tester(expected, method, cs, type_id, klass)
    geom = Geos.send(method, cs)
    expected_geom = read(expected)

    assert(expected_geom.eql_exact?(geom, TOLERANCE))
    assert(geom.valid?)
    assert_instance_of(klass, geom)
    assert_equal(type_id, geom.type_id)

    yield geom if block_given?
  end

  def test_create_point
    cs = Geos::CoordinateSequence.new(1, 2)
    cs.set_x(0, 10)
    cs.set_y(0, 20)

    create_method_tester('POINT(10 20)', :create_point, cs, Geos::GEOS_POINT, Geos::Point)
  end

  def test_bad_create_point
    cs = Geos::CoordinateSequence.new(0, 0)
    assert_raise(RuntimeError) do
      geom = Geos.create_point(cs)
    end
  end

  def test_create_line_string
    cs = Geos::CoordinateSequence.new(2, 3)
    cs.set_x(0, 10)
    cs.set_y(0, 20)
    cs.set_z(0, 30)
    cs.set_x(1, 30)
    cs.set_y(1, 20)
    cs.set_z(1, 10)

    create_method_tester(
      'LINESTRING (10 20 30, 30 20 10)',
      :create_line_string,
      cs,
      Geos::GEOS_LINESTRING,
      Geos::LineString
    ) do |geom|
      assert(!geom.empty?)
      assert(geom.valid?)
      assert(geom.simple?)
      assert(!geom.ring?)
      assert(geom.has_z?)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_create_bad_line_string
    cs = Geos::CoordinateSequence.new(1, 0)
    assert_raise(RuntimeError) do
      geom = Geos::create_line_string(cs)
    end
  end

  def test_create_linear_ring
    cs = Geos::CoordinateSequence.new(4,3)
    cs.set_x(0, 7)
    cs.set_y(0, 8)
    cs.set_z(0, 9)
    cs.set_x(1, 3)
    cs.set_y(1, 3)
    cs.set_z(1, 3)
    cs.set_x(2, 11)
    cs.set_y(2, 15.2)
    cs.set_z(2, 2)
    cs.set_x(3, 7)
    cs.set_y(3, 8)
    cs.set_z(3, 9)

    create_method_tester(
      'LINEARRING (7 8 9, 3 3 3, 11 15.2 2, 7 8 9)',
      :create_linear_ring,
      cs,
      Geos::GEOS_LINEARRING,
      Geos::LinearRing
    ) do |geom|
      assert(!geom.empty?)
      assert(geom.valid?)
      assert(geom.simple?)
      assert(geom.ring?)
      assert(geom.has_z?)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_bad_create_linear_ring
    cs = Geos::CoordinateSequence.new(1, 0)

    assert_raise(RuntimeError) do
      geom = Geos::create_linear_ring(cs)
    end
  end

  def test_create_polygon
    cs = Geos::CoordinateSequence.new([
      [ 0, 0 ],
      [ 0, 10 ],
      [ 10, 10 ],
      [ 10, 0 ],
      [ 0, 0 ]
    ])

    exterior_ring = Geos::create_linear_ring(cs)

    geom = Geos::create_polygon(exterior_ring)
    assert_instance_of(Geos::Polygon, geom)
    assert_equal('Polygon', geom.geom_type)
    assert_equal(Geos::GEOS_POLYGON, geom.type_id)
    assert_equal('POLYGON ((0 0, 0 10, 10 10, 10 0, 0 0))', write(geom, :trim => true))
  end

  def test_create_polygon_with_coordinate_sequences
    outer = Geos::CoordinateSequence.new(
      [ 0, 0 ],
      [ 0, 10 ],
      [ 10, 10 ],
      [ 10, 0 ],
      [ 0, 0 ]
    )

    inner = Geos::CoordinateSequence.new(
      [ 2, 2 ],
      [ 2, 4 ],
      [ 4, 4 ],
      [ 4, 2 ],
      [ 2, 2 ]
    )

    geom = Geos::create_polygon(outer, inner)
    assert_instance_of(Geos::Polygon, geom)
    assert_equal('Polygon', geom.geom_type)
    assert_equal(Geos::GEOS_POLYGON, geom.type_id)
    assert_equal('POLYGON ((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 4, 4 4, 4 2, 2 2))', write(geom, :trim => true))
  end

  def test_create_polygon_with_holes
    exterior_ring = Geos::CoordinateSequence.new(
      [ 0, 0 ],
      [ 0, 10 ],
      [ 10, 10 ],
      [ 10, 0 ],
      [ 0, 0 ]
    )

    hole_1 = Geos::CoordinateSequence.new(
      [ 2, 2 ],
      [ 2, 4 ],
      [ 4, 4 ],
      [ 4, 2 ],
      [ 2, 2 ]
    )

    hole_2 = Geos::CoordinateSequence.new(
      [ 6, 6 ],
      [ 6, 8 ],
      [ 8, 8 ],
      [ 8, 6 ],
      [ 6, 6 ]
    )

    geom = Geos::create_polygon(exterior_ring, [ hole_1, hole_2 ])
    assert_instance_of(Geos::Polygon, geom)
    assert_equal('Polygon', geom.geom_type)
    assert_equal(Geos::GEOS_POLYGON, geom.type_id)

    assert(!geom.empty?)
    assert(geom.valid?)
    assert(geom.simple?)
    assert(!geom.ring?)
    assert(!geom.has_z?)

    assert_equal(1, geom.num_geometries)
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_point)
    def test_create_multi_point
      @writer.rounding_precision = 0
      assert_equal('MULTIPOINT EMPTY', write(Geos.create_multi_point))
      assert_equal('MULTIPOINT (0 0, 10 10)', write(Geos.create_multi_point(
        read('POINT(0 0)'),
        read('POINT(10 10)')
      )))
    end

    def test_create_bad_multi_point
      assert_raise(TypeError) do
        Geos.create_multi_point(
          read('POINT(0 0)'),
          read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
        )
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_line_string)
    def test_create_multi_line_string
      @writer.rounding_precision = 0
      assert_equal('MULTILINESTRING EMPTY', write(Geos.create_multi_line_string))
      assert_equal('MULTILINESTRING ((0 0, 10 10), (10 10, 20 20))', write(Geos.create_multi_line_string(
        read('LINESTRING(0 0, 10 10)'),
        read('LINESTRING(10 10, 20 20)')
      )))
    end

    def test_create_bad_multi_line_string
      assert_raise(TypeError) do
        Geos.create_multi_point(
          read('POINT(0 0)'),
          read('LINESTRING(0 0, 10 0)')
        )
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_polygon)
    def test_create_multi_polygon
      @writer.rounding_precision = 0
      assert_equal('MULTIPOLYGON EMPTY', write(Geos.create_multi_polygon))
      assert_equal('MULTIPOLYGON (((0 0, 0 5, 5 5, 5 0, 0 0)), ((10 10, 10 15, 15 15, 15 10, 10 10)))', write(Geos.create_multi_polygon(
        read('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))'),
        read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
      )))
    end

    def test_create_bad_multi_polygon
      assert_raise(TypeError) do
        Geos.create_multi_polygon(
          read('POINT(0 0)'),
          read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
        )
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_geometry_collection)
    def test_create_geometry_collection
      @writer.rounding_precision = 0
      assert_equal('GEOMETRYCOLLECTION EMPTY', write(Geos.create_geometry_collection))
      assert_equal('GEOMETRYCOLLECTION (POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0)), POLYGON ((10 10, 10 15, 15 15, 15 10, 10 10)))',
        write(Geos.create_geometry_collection(
          read('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))'),
          read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
        ))
      )
    end

    def test_create_geometry_collection_with_constants_and_symbols
      assert_kind_of(Geos::MultiLineString, Geos.create_collection(Geos::GeomTypes::GEOS_MULTILINESTRING))
      assert_kind_of(Geos::MultiLineString, Geos.create_collection(:multi_line_string))
    end

    def test_create_bad_geometry_collection
      assert_raise(TypeError) do
        Geos.create_geometry_collection(
          read('POINT(0 0)'),
          read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))'),
          'gibberish'
        )
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_point)
    def test_create_empty_point
      assert_equal('POINT EMPTY', write(Geos.create_empty_point))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_line_string)
    def test_create_empty_line_string
      assert_equal('LINESTRING EMPTY', write(Geos.create_empty_line_string))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_polygon)
    def test_create_empty_polygon
      assert_equal('POLYGON EMPTY', write(Geos.create_empty_polygon))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_multi_point)
    def test_create_empty_multi_point
      assert_equal('MULTIPOINT EMPTY', write(Geos.create_empty_multi_point))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_multi_line_string)
    def test_create_empty_multi_line_string
      assert_equal('MULTILINESTRING EMPTY', write(Geos.create_empty_multi_line_string))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_multi_polygon)
    def test_create_empty_multi_polygon
      assert_equal('MULTIPOLYGON EMPTY', write(Geos.create_empty_multi_polygon))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_geometry_collection)
    def test_create_empty_geometry_collection
      assert_equal('GEOMETRYCOLLECTION EMPTY', write(Geos.create_empty_geometry_collection))
    end
  end

  if ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_linear_ring)
    def test_create_empty_linear_ring
      assert_equal('LINEARRING EMPTY', write(Geos.create_empty_linear_ring))
    end
  end
end
