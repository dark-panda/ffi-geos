
$: << File.dirname(__FILE__)
require 'test_helper'

if defined?(Geos::Utils)
  class UtilsTests < Test::Unit::TestCase
    include TestHelper

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
end
