
$: << File.dirname(__FILE__)
require 'test_helper'

if defined?(Geos::STRtree)
  class STRtreeTests < Test::Unit::TestCase
    include TestHelper

    def setup_tree
      @tree = Geos::STRtree.new(3)
      @item_1 = { :item_1 => :test }
      @item_2 = [ :test ]
      @item_3 = Object.new

      @geom_1 = read('LINESTRING(0 0, 10 10)')
      @geom_2 = read('LINESTRING(20 20, 30 30)')
      @geom_3 = read('LINESTRING(20 20, 30 30)')

      @tree.insert(@geom_1, @item_1)
      @tree.insert(@geom_2, @item_2)
      @tree.insert(@geom_3, @item_3)
    end

    def test_disallowed_inserts
      setup_tree

      @tree.query(read('POINT(5 5)'))

      assert_raise(RuntimeError) do
        @tree.insert(read('POINT(0 0)'), 'test')
      end
    end

    def test_query
      setup_tree

      assert_equal([@item_1],
        @tree.query(read('LINESTRING(5 5, 6 6)')))

      assert_equal([],
        @tree.query(read('LINESTRING(20 0, 30 10)')))

      assert_equal([@item_2, @item_3],
        @tree.query(read('LINESTRING(25 25, 26 26)')))

      assert_equal([@item_1, @item_2, @item_3],
        @tree.query(read('LINESTRING(0 0, 100 100)')))
    end

    def test_query_with_ret_keys
      setup_tree

      assert_equal([@item_1],
        @tree.query(read('LINESTRING(5 5, 6 6)'), :item))

      assert_equal([],
        @tree.query(read('LINESTRING(20 0, 30 10)'), :item))

      assert_equal([@item_2, @item_3],
        @tree.query(read('LINESTRING(25 25, 26 26)'), :item))

      assert_equal([@item_1, @item_2, @item_3],
        @tree.query(read('LINESTRING(0 0, 100 100)'), :item))


      assert_equal([@geom_1],
        @tree.query(read('LINESTRING(5 5, 6 6)'), :geometry))

      assert_equal([],
        @tree.query(read('LINESTRING(20 0, 30 10)'), :geometry))

      assert_equal([@geom_2, @geom_3],
        @tree.query(read('LINESTRING(25 25, 26 26)'), :geometry))

      assert_equal([@geom_1, @geom_2, @geom_3],
        @tree.query(read('LINESTRING(0 0, 100 100)'), :geometry))


      assert_equal(
        [
          { :item => @item_1, :geometry => @geom_1 }
        ],
        @tree.query(read('LINESTRING(5 5, 6 6)'), :all)
      )

      assert_equal([],
        @tree.query(read('LINESTRING(20 0, 30 10)'), :all))

      assert_equal(
        [
          { :item => @item_2, :geometry => @geom_2 },
          { :item => @item_3, :geometry => @geom_3 }
        ],
        @tree.query(read('LINESTRING(25 25, 26 26)'), :all)
      )

      assert_equal(
        [
          { :item => @item_1, :geometry => @geom_1 },
          { :item => @item_2, :geometry => @geom_2 },
          { :item => @item_3, :geometry => @geom_3 }
        ],
        @tree.query(read('LINESTRING(0 0, 100 100)'), :all)
      )
    end

    def test_query_all
      setup_tree

      assert_equal([@item_1],
        @tree.query_all(read('LINESTRING(5 5, 6 6)')).collect { |v| v[:item] })

      assert_equal([],
        @tree.query_all(read('LINESTRING(20 0, 30 10)')))

      assert_equal([@item_2, @item_3],
        @tree.query_all(read('LINESTRING(25 25, 26 26)')).collect { |v| v[:item] })

      assert_equal([@item_1, @item_2, @item_3],
        @tree.query_all(read('LINESTRING(0 0, 100 100)')).collect { |v| v[:item] })
    end

    def test_query_geometries
      setup_tree

      assert_equal([@geom_1],
        @tree.query_geometries(read('LINESTRING(5 5, 6 6)')))

      assert_equal([],
        @tree.query_geometries(read('LINESTRING(20 0, 30 10)')))

      assert_equal([@geom_2, @geom_3],
        @tree.query_geometries(read('LINESTRING(25 25, 26 26)')))

      assert_equal([@geom_1, @geom_2, @geom_3],
        @tree.query_geometries(read('LINESTRING(0 0, 100 100)')))
    end

    def test_remove
      setup_tree

      @tree.remove(read('POINT(5 5)'), @item_1)

      assert_equal([],
        @tree.query(read('LINESTRING(5 5, 6 6)')))

      assert_equal([],
        @tree.query(read('LINESTRING(20 0, 30 10)')))

      assert_equal([@item_2, @item_3],
        @tree.query(read('LINESTRING(25 25, 26 26)')))

      assert_equal([@item_2, @item_3],
        @tree.query(read('LINESTRING(0 0, 100 100)')))
    end

    def test_cant_clone
      assert_raise(NoMethodError) do
        Geos::STRtree.new(3).clone
      end
    end

    def test_cant_dup
      assert_raise(NoMethodError) do
        Geos::STRtree.new(3).dup
      end
    end

    def test_setup_with_array
      tree = Geos::STRtree.new(
        [ read('LINESTRING(0 0, 10 10)'), item_1 = { :item_1 => :test } ],
        [ read('LINESTRING(20 20, 30 30)'), item_2 = [ :test ] ],
        [ read('LINESTRING(20 20, 30 30)'), item_3 = Object.new ]
      )

      assert_equal([item_1],
        tree.query(read('LINESTRING(5 5, 6 6)')))

      assert_equal([],
        tree.query(read('LINESTRING(20 0, 30 10)')))

      assert_equal([item_2, item_3],
        tree.query(read('LINESTRING(25 25, 26 26)')))

      assert_equal([item_1, item_2, item_3],
        tree.query(read('LINESTRING(0 0, 100 100)')))
    end

    def test_capacity
      assert_raise(ArgumentError) do
        Geos::STRtree.new(0)
      end
    end

    def test_geometries
      assert_raise(TypeError) do
        Geos::STRtree.new([])
      end
    end
  end
end
