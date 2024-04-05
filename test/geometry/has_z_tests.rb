# frozen_string_literal: true

require 'test_helper'

class GeometryHasZTests < Minitest::Test
  include TestHelper

  def setup
    super
    writer.trim = true
  end

  def test_has_z
    refute_geom_has_z(read('POINT(0 0)'))
    assert_geom_has_z(read('POINT(0 0 0)'))
  end
end
