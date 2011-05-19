
$: << File.dirname(__FILE__)
require 'test_helper'

class MiscTests < Test::Unit::TestCase
  include TestHelper

  def thread_tester(name, dims, byte_order, polygon, pause)
    msg = proc { |*args| @messages << "#{name}: #{args.inspect}" }

    3.times {
      sleep(pause)
      wktr = Geos::WktReader.new
      wkbw = Geos::WkbWriter.new
      wkbw.byte_order = byte_order
      wkbw.output_dimensions = dims
      geom = wktr.read(polygon)
      msg[geom.valid?]
      msg[wkbw.write_hex(geom)]
      GC.start
    }
  end

  def test_multithreading
    @messages = []

    t1 = Thread.new {
      thread_tester('t1', 2, 0, 'POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))', 0.2)
    }

    t2 = Thread.new {
      thread_tester('t2', 3, 1, 'POLYGON((0 0 0, 0 5 0, 5 5 0, 5 10 0, 0 0 0))', 0.1)
    }

    t1.join
    t2.join

    assert_equal([
      "t1: [\"000000000300000001000000050000000000000000000000000000000000000000000000004014000000000000401400000000000040140000000000004014000000000000000000000000000000000000000000000000000000000000\"]",
      "t1: [\"000000000300000001000000050000000000000000000000000000000000000000000000004014000000000000401400000000000040140000000000004014000000000000000000000000000000000000000000000000000000000000\"]",
      "t1: [\"000000000300000001000000050000000000000000000000000000000000000000000000004014000000000000401400000000000040140000000000004014000000000000000000000000000000000000000000000000000000000000\"]",
      "t1: [true]",
      "t1: [true]",
      "t1: [true]",
      "t2: [\"01030000800100000005000000000000000000000000000000000000000000000000000000000000000000000000000000000014400000000000000000000000000000144000000000000014400000000000000000000000000000144000000000000024400000000000000000000000000000000000000000000000000000000000000000\"]",
      "t2: [\"01030000800100000005000000000000000000000000000000000000000000000000000000000000000000000000000000000014400000000000000000000000000000144000000000000014400000000000000000000000000000144000000000000024400000000000000000000000000000000000000000000000000000000000000000\"]",
      "t2: [\"01030000800100000005000000000000000000000000000000000000000000000000000000000000000000000000000000000014400000000000000000000000000000144000000000000014400000000000000000000000000000144000000000000024400000000000000000000000000000000000000000000000000000000000000000\"]",
      "t2: [false]",
      "t2: [false]",
      "t2: [false]"
    ], @messages.sort)
  end

  def test_segfault_on_cs_ownership
    cs = Geos::CoordinateSequence.new(1, 2)
    cs.set_x(0, 1)
    cs.set_y(0, 2)

    point = Geos.create_point(cs)
    collection_a = Geos.create_geometry_collection(point)
    collection_b = Geos.create_geometry_collection(point)

    GC.start

    writer.rounding_precision = 0

    assert_equal('POINT (1 2)', write(point))
    assert_equal(collection_a[0], point)
    assert_equal(collection_a[0], collection_b[0])
  end

  def test_segfault_on_geom_ownership
    point = read('POINT (10 20)')

    collection_a = Geos.create_geometry_collection(point)
    collection_b = Geos.create_geometry_collection(collection_a[0])

    GC.start

    writer.rounding_precision = 0

    assert_equal('POINT (10 20)', write(point))
    assert_equal(collection_a[0], point)
    assert_equal(collection_a[0], collection_b[0])
  end

  def test_cant_clone_buffer_params
    assert_raise(NoMethodError) do
      Geos::BufferParams.new.clone
    end
  end

  def test_cant_dup_buffer_params
    assert_raise(NoMethodError) do
      Geos::BufferParams.new.dup
    end
  end
end
