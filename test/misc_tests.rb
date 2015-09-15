# encoding: UTF-8
# frozen_string_literal: true

$: << File.dirname(__FILE__)
require 'test_helper'

class MiscTests < Minitest::Test
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

  def test_segfault_on_coord_seq_parents
    geom = read('LINESTRING(0 0, 1 0)')
    cs = geom.envelope.exterior_ring.coord_seq

    GC.start

    assert_equal('0.0 0.0, 1.0 0.0, 1.0 0.0, 0.0 0.0, 0.0 0.0', cs.to_s)
  end

  def test_cant_clone_buffer_params
    assert_raises(NoMethodError) do
      Geos::BufferParams.new.clone
    end
  end

  def test_cant_dup_buffer_params
    assert_raises(NoMethodError) do
      Geos::BufferParams.new.dup
    end
  end

  def notice_handler_tester
    results = ''.dup
    geom = read('POLYGON((0 0, 0 5, 5 0, 5 5, 0 0))')

    yield results

    refute(geom.valid?, "Expected geom to be invalid")
    assert_match(/^NOTICE: .+$/, results)
  ensure
    Geos.current_handle.reset_notice_handler
  end

  def notice_handler_method(results, *args)
    results << "NOTICE: #{args[0] % args[1]}"
  end

  def test_setting_notice_handler_with_method
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:notice_handler=)

    notice_handler_tester do |results|
      Geos.current_handle.notice_handler = method(:notice_handler_method).curry(2)[results]
    end
  end

  def test_setting_notice_handler_with_proc
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:notice_handler=)

    notice_handler_tester do |results|
      Geos.current_handle.notice_handler = proc do |*args|
        results << "NOTICE: #{args[0] % args[1]}"
      end
    end
  end

  def test_setting_notice_handler_with_block
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:notice_handler=)

    notice_handler_tester do |results|
      Geos.current_handle.notice_handler do |*args|
        results << "NOTICE: #{args[0] % args[1]}"
      end
    end
  end

  def error_handler_tester
    results = ''.dup
    geom = nil

    yield results

    assert_raises(RuntimeError) do
      geom = read('POLYGON((0 0, 0 5, 5 0, 5 5))')
    end

    assert_nil(geom)
    assert_match(/^ERROR: .+$/, results)
  ensure
    Geos.current_handle.reset_error_handler
  end

  def error_handler_method(results, *args)
    message = "ERROR: #{args[0] % args[1]}".dup
    results << message
    raise message
  end

  def test_setting_error_handler_with_method
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:error_handler=)

    error_handler_tester do |results|
      Geos.current_handle.error_handler = method(:error_handler_method).curry(2)[results]
    end
  end

  def test_setting_error_handler_with_proc
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:error_handler=)

    error_handler_tester do |results|
      Geos.current_handle.error_handler = proc do |*args|
        message = "ERROR: #{args[0] % args[1]}".dup
        results << message
        raise message
      end
    end
  end

  def test_setting_error_handler_with_block
    skip unless ENV['FORCE_TESTS'] || Geos::Handle.method_defined?(:error_handler=)

    error_handler_tester do |results|
      Geos.current_handle.error_handler do |*args|
        message = "ERROR: #{args[0] % args[1]}".dup
        results << message
        raise message
      end
    end
  end
end
