# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class UtilsTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_orientation_index
    skip unless ENV['FORCE_TESTS'] || (defined?(Geos::Utils) && Geos::Utils.respond_to?(:orientation_index))

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

  def test_relate_match
    skip unless ENV['FORCE_TESTS'] || (defined?(Geos::Utils) && Geos::Utils.respond_to?(:relate_match))

    assert(Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFF2'), "'0FFFFFFF2' and '0FFFFFFF2' patterns match")
    assert(Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFF*'), "'0FFFFFFF2' and '0FFFFFFF*' patterns match")
    assert(Geos::Utils.relate_match('0FFFFFFF2', 'TFFFFFFF2'), "'0FFFFFFF2' and 'TFFFFFFF2' patterns match")
    assert(!Geos::Utils.relate_match('0FFFFFFF2', '0FFFFFFFF'), "'0FFFFFFF2' and '0FFFFFFFF' patterns match")
  end

  def create_method_tester(expected, method, cs, type_id, klass)
    geom = Geos.send(method, cs)
    expected_geom = read(expected)

    assert_geom_eql_exact(expected_geom, geom)
    assert_geom_valid(geom)
    assert_kind_of(klass, geom)
    assert_equal(type_id, geom.type_id)

    yield geom if block_given?
  end

  def test_create_point
    cs = Geos::CoordinateSequence.new(1, 2)
    cs.set_x(0, 10)
    cs.set_y(0, 20)

    create_method_tester('POINT(10 20)', :create_point, cs, Geos::GEOS_POINT, Geos::Point)
  end

  def test_create_point_with_x_and_y_arguments
    assert_equal('POINT (10 20)', write(Geos.create_point(10, 20), :trim => true))
  end

  def test_create_point_with_x_y_and_z_arguments
    assert_equal('POINT Z (10 20 30)', write(Geos.create_point(10, 20, 30), :trim => true, :output_dimensions => 3))
  end

  def test_create_point_with_too_many_arguments
    assert_raises(ArgumentError) do
      Geos.create_point(10, 20, 30, 40, 50)
    end
  end

  def test_bad_create_point
    cs = Geos::CoordinateSequence.new(0, 0)
    assert_raises(RuntimeError) do
      Geos.create_point(cs)
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
      refute_geom_empty(geom)
      assert_geom_valid(geom)
      assert_geom_simple(geom)
      refute_geom_ring(geom)
      assert_geom_has_z(geom)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_create_line_string_with_array
    writer.output_dimensions = 3

    create_method_tester(
      'LINESTRING Z (10 20 30, 30 20 10)',
      :create_line_string,
      [[ 10, 20, 30 ], [ 30, 20, 10 ]],
      Geos::GEOS_LINESTRING,
      Geos::LineString
    ) do |geom|
      refute_geom_empty(geom)
      assert_geom_valid(geom)
      assert_geom_simple(geom)
      refute_geom_ring(geom)
      assert_geom_has_z(geom)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_create_bad_line_string
    cs = Geos::CoordinateSequence.new(1, 0)
    assert_raises(RuntimeError) do
      Geos::create_line_string(cs)
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
      refute_geom_empty(geom)
      assert_geom_valid(geom)
      assert_geom_simple(geom)
      assert_geom_ring(geom)
      assert_geom_has_z(geom)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_create_linear_ring_with_array
    writer.output_dimensions = 3

    create_method_tester(
      'LINEARRING Z (7 8 9, 3 3 3, 11 15.2 2, 7 8 9)',
      :create_linear_ring,
      [[ 7, 8, 9 ], [ 3, 3, 3 ], [ 11, 15.2, 2 ], [ 7, 8, 9 ]],
      Geos::GEOS_LINEARRING,
      Geos::LinearRing
    ) do |geom|
      refute_geom_empty(geom)
      assert_geom_valid(geom)
      assert_geom_simple(geom)
      assert_geom_ring(geom)
      assert_geom_has_z(geom)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_bad_create_linear_ring
    cs = Geos::CoordinateSequence.new(1, 0)

    assert_raises(RuntimeError) do
      Geos::create_linear_ring(cs)
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

    refute_geom_empty(geom)
    assert_geom_valid(geom)
    assert_geom_simple(geom)
    refute_geom_ring(geom)
    refute_geom_has_z(geom)

    assert_equal(1, geom.num_geometries)
  end

  def test_create_multi_point
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_point)

    writer.rounding_precision = 0
    assert_equal('MULTIPOINT EMPTY', write(Geos.create_multi_point))
    assert_equal('MULTIPOINT (0 0, 10 10)', write(Geos.create_multi_point(
      read('POINT(0 0)'),
      read('POINT(10 10)')
    )))
  end

  def test_create_bad_multi_point
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_point)

    assert_raises(TypeError) do
      Geos.create_multi_point(
        read('POINT(0 0)'),
        read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
      )
    end
  end

  def test_create_multi_line_string
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_line_string)

    writer.rounding_precision = 0
    assert_equal('MULTILINESTRING EMPTY', write(Geos.create_multi_line_string))
    assert_equal('MULTILINESTRING ((0 0, 10 10), (10 10, 20 20))', write(Geos.create_multi_line_string(
      read('LINESTRING(0 0, 10 10)'),
      read('LINESTRING(10 10, 20 20)')
    )))
  end

  def test_create_bad_multi_line_string
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_line_string)

    assert_raises(TypeError) do
      Geos.create_multi_point(
        read('POINT(0 0)'),
        read('LINESTRING(0 0, 10 0)')
      )
    end
  end

  def test_create_multi_polygon
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_polygon)

    writer.rounding_precision = 0
    assert_equal('MULTIPOLYGON EMPTY', write(Geos.create_multi_polygon))
    assert_equal('MULTIPOLYGON (((0 0, 0 5, 5 5, 5 0, 0 0)), ((10 10, 10 15, 15 15, 15 10, 10 10)))', write(Geos.create_multi_polygon(
      read('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))'),
      read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
    )))
  end

  def test_create_bad_multi_polygon
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_polygon)

    assert_raises(TypeError) do
      Geos.create_multi_polygon(
        read('POINT(0 0)'),
        read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
      )
    end
  end

  def test_create_geometry_collection
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_geometry_collection)

    writer.rounding_precision = 0
    assert_equal('GEOMETRYCOLLECTION EMPTY', write(Geos.create_geometry_collection))
    assert_equal('GEOMETRYCOLLECTION (POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0)), POLYGON ((10 10, 10 15, 15 15, 15 10, 10 10)))',
      write(Geos.create_geometry_collection(
        read('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))'),
        read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))')
      ))
    )
  end

  def test_create_geometry_collection_with_constants_and_symbols
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_geometry_collection)

    assert_kind_of(Geos::MultiLineString, Geos.create_collection(Geos::GeomTypes::GEOS_MULTILINESTRING))
    assert_kind_of(Geos::MultiLineString, Geos.create_collection(:multi_line_string))
  end

  def test_create_bad_geometry_collection
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_geometry_collection)

    assert_raises(TypeError) do
      Geos.create_geometry_collection(
        read('POINT(0 0)'),
        read('POLYGON((10 10, 10 15, 15 15, 15 10, 10 10))'),
        'gibberish'
      )
    end
  end

  def test_create_geometry_collection_with_options
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_geometry_collection)

    geom = Geos.create_collection(:multi_line_string, :srid => 4326)

    assert_kind_of(Geos::MultiLineString, geom)
    assert_equal(4326, geom.srid)
  end

  def test_create_empty_point
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_point)

    assert_equal('POINT EMPTY', write(Geos.create_empty_point))
  end

  def test_create_empty_line_string
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_line_string)

    assert_equal('LINESTRING EMPTY', write(Geos.create_empty_line_string))
  end

  def test_create_empty_polygon
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_polygon)

    assert_equal('POLYGON EMPTY', write(Geos.create_empty_polygon))
  end

  def test_create_empty_multi_point
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_multi_point)

    assert_equal('MULTIPOINT EMPTY', write(Geos.create_empty_multi_point))
  end

  def test_create_empty_multi_line_string
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_multi_line_string)

    assert_equal('MULTILINESTRING EMPTY', write(Geos.create_empty_multi_line_string))
  end

  def test_create_empty_multi_polygon
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_multi_polygon)

    assert_equal('MULTIPOLYGON EMPTY', write(Geos.create_empty_multi_polygon))
  end

  def test_create_empty_geometry_collection
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_geometry_collection)

    assert_equal('GEOMETRYCOLLECTION EMPTY', write(Geos.create_empty_geometry_collection))
  end

  def test_create_empty_linear_ring
    skip unless ENV['FORCE_TESTS'] || Geos.respond_to?(:create_empty_linear_ring)

    assert_equal('LINEARRING EMPTY', write(Geos.create_empty_linear_ring))
  end

  def test_create_geometry_segfault
    # This used to segfault before moving the autorelease code to before
    # the initialization. It didn't occur 100% of the time. The cause was
    # GEOS taking ownership of CoordinateSequences and deleting them out from
    # under us and GC blowing up.

    assert_raises(RuntimeError) do
      cs = Geos::CoordinateSequence.new(0, 2)
      Geos.create_point(cs)
      GC.start
    end

    assert_raises(RuntimeError) do
      cs = Geos::CoordinateSequence.new(1, 2)
      Geos.create_line_string(cs)
      GC.start
    end

    assert_raises(RuntimeError) do
      cs = Geos::CoordinateSequence.new(1, 2)
      Geos.create_linear_ring(cs)
      GC.start
    end

    assert_raises(RuntimeError) do
      cs = Geos::CoordinateSequence.new([
        [0, 0],
        [0, 5],
        [5, 5],
        [0, 5]
      ])
      Geos.create_linear_ring(cs)
      GC.start
    end
  end
end
