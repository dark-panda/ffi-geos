
$: << File.dirname(__FILE__)
require 'test_helper'

class CoordinateSequenceTests < Test::Unit::TestCase
  include TestHelper

  def setup
    @cs = Geos::CoordinateSequence.new(3, 0)
    super
  end

  def test_set_and_get_x
    @cs.set_x(0, 10.01)
    assert_in_delta(10.01, @cs.get_x(0), TOLERANCE)
  end

  def test_set_and_get_y
    @cs.set_y(0, 20.02)
    assert_in_delta(20.02, @cs.get_y(0), TOLERANCE)
  end

  def test_set_and_get_z
    @cs.set_z(0, 20.02)
    assert_in_delta(20.02, @cs.get_z(0), TOLERANCE)
  end

  def test_set_and_get_ordinate
    @cs.set_ordinate(0, 0, 10.01)
    @cs.set_ordinate(0, 1, 20.02)
    @cs.set_ordinate(0, 2, 30.03)

    assert_in_delta(10.01, @cs.get_ordinate(0, 0), TOLERANCE)
    assert_in_delta(20.02, @cs.get_ordinate(0, 1), TOLERANCE)
    assert_in_delta(30.03, @cs.get_ordinate(0, 2), TOLERANCE)
  end

  def test_length
    assert_equal(3, @cs.length)
  end

  def test_dimensions
    assert_equal(2, @cs.dimensions)
  end

  def test_check_bounds
    assert_raise(RuntimeError) { @cs.set_x(10, 0.1) }
    assert_raise(RuntimeError) { @cs.set_x(-1, 0.1) }

    assert_raise(RuntimeError) { @cs.set_y(10, 0.1) }
    assert_raise(RuntimeError) { @cs.set_y(-1, 0.1) }

    assert_raise(RuntimeError) { @cs.set_z(10, 0.1) }
    assert_raise(RuntimeError) { @cs.set_z(-1, 0.1) }

    assert_raise(RuntimeError) { @cs.set_ordinate(10, 0, 0.1) }
    assert_raise(RuntimeError) { @cs.set_ordinate(-1, 0, 0.1) }

    assert_raise(RuntimeError) { @cs.get_x(10) }
    assert_raise(RuntimeError) { @cs.get_x(-1) }

    assert_raise(RuntimeError) { @cs.get_y(10) }
    assert_raise(RuntimeError) { @cs.get_y(-1) }

    assert_raise(RuntimeError) { @cs.get_z(10) }
    assert_raise(RuntimeError) { @cs.get_z(-1) }

    assert_raise(RuntimeError) { @cs.get_ordinate(10, 0) }
    assert_raise(RuntimeError) { @cs.get_ordinate(-1, 0) }
  end

  def test_clone
    @cs.set_x(0, 1)
    @cs.set_y(0, 2)

    cs_b = @cs.clone

    assert_equal(@cs.get_x(0), cs_b.get_x(0))
    assert_equal(@cs.get_y(0), cs_b.get_y(0))
    assert_equal(@cs.dimensions, cs_b.dimensions)
  end

  def test_dup
    @cs.set_x(0, 1)
    @cs.set_y(0, 2)

    cs_b = @cs.dup

    assert_equal(@cs.get_x(0), cs_b.get_x(0))
    assert_equal(@cs.get_y(0), cs_b.get_y(0))
    assert_equal(@cs.dimensions, cs_b.dimensions)
  end

  def test_with_no_arguments
    cs = Geos::CoordinateSequence.new
    assert_equal(0, cs.size)
    assert_equal(3, cs.dimensions)
  end

  def test_read_from_array
    cs = Geos::CoordinateSequence.new([
      [ 0, 0 ],
      [ 1, 1 ],
      [ 2, 2 ],
      [ 3, 3 ],
      [ 4, 4 ]
    ])

    assert_equal(2, cs.dimensions)
    assert_equal(5, cs.length)

    assert_raise(Geos::CoordinateSequence::ParseError) do
      cs = Geos::CoordinateSequence.new([
        [ 1, 2 ],
        [ 1, 2, 3 ]
      ])
    end

    assert_raise(Geos::CoordinateSequence::ParseError) do
      cs = Geos::CoordinateSequence.new([
        [ 1, 2, 3, 4 ]
      ])
    end
  end

  def test_to_point
    cs = Geos::CoordinateSequence.new([5,7])
    assert_equal('POINT (5 7)', write(cs.to_point, :trim => true))
  end

  def test_to_to_linear_ring
    cs = Geos::CoordinateSequence.new([
      [ 0, 0 ],
      [ 0, 5 ],
      [ 5, 5 ],
      [ 5, 0 ],
      [ 0, 0 ]
    ])

    assert_equal('LINEARRING (0 0, 0 5, 5 5, 5 0, 0 0)', write(cs.to_linear_ring, :trim => true))
  end

  def test_empty
    cs = Geos::CoordinateSequence.new
    assert(cs.empty?)

    cs = Geos::CoordinateSequence.new([4,1])
    assert(!cs.empty?)
  end

  def test_to_empty_linear_ring
    cs = Geos::CoordinateSequence.new

    assert_equal('LINEARRING EMPTY', write(cs.to_linear_ring, :trim => true))
  end

  def test_to_line_string
    cs = Geos::CoordinateSequence.new([
      [ 0, 0 ],
      [ 0, 5 ],
      [ 5, 5 ],
      [ 5, 0 ]
    ])

    assert_equal('LINESTRING (0 0, 0 5, 5 5, 5 0)', write(cs.to_line_string, :trim => true))
  end

  def test_to_empty_line_string
    cs = Geos::CoordinateSequence.new

    assert_equal('LINESTRING EMPTY', write(cs.to_line_string, :trim => true))
  end

  def test_to_polygon
    cs = Geos::CoordinateSequence.new([
      [ 0, 0 ],
      [ 0, 5 ],
      [ 5, 5 ],
      [ 5, 0 ],
      [ 0, 0 ]
    ])

    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(cs.to_polygon, :trim => true))
  end

  def test_to_empty_polygon
    cs = Geos::CoordinateSequence.new

    assert_equal('POLYGON EMPTY', write(cs.to_polygon, :trim => true))
  end

  def test_to_s
    cs = Geos::CoordinateSequence.new([[1, 2], [10, 11]])
    assert_equal("1.0 2.0, 10.0 11.0", cs.to_s)

    cs = Geos::CoordinateSequence.new([[1, 2, 3], [10, 11, 12]])
    assert_equal("1.0 2.0 3.0, 10.0 11.0 12.0", cs.to_s)
  end
end
