
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

      assert_equal(1, @tree.query(read('LINESTRING(5 5, 6 6)')).length)
      assert_equal(0, @tree.query(read('LINESTRING(20 0, 30 10)')).length)
      assert_equal(2, @tree.query(read('LINESTRING(25 25, 26 26)')).length)
      assert_equal(3, @tree.query(read('LINESTRING(0 0, 100 100)')).length)
    end

    def test_remove
      setup_tree

      @tree.remove(read('POINT(5 5)'), @item_1)

      assert_equal(0, @tree.query(read('LINESTRING(5 5, 6 6)')).length)
      assert_equal(0, @tree.query(read('LINESTRING(20 0, 30 10)')).length)
      assert_equal(2, @tree.query(read('LINESTRING(25 25, 26 26)')).length)
      assert_equal(2, @tree.query(read('LINESTRING(0 0, 100 100)')).length)
    end
  end
end
