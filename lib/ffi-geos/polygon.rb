# frozen_string_literal: true

module Geos
  class Polygon < Geometry
    def num_interior_rings
      FFIGeos.GEOSGetNumInteriorRings_r(Geos.current_handle_pointer, self.ptr)
    end

    def interior_ring_n(n)
      if n < 0 || n >= self.num_interior_rings
        raise Geos::IndexBoundsError.new
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGetInteriorRingN_r(Geos.current_handle_pointer, self.ptr, n), {
            :auto_free => false,
            :srid_copy => self.srid,
            :parent => self
          }
        )
      end
    end
    alias_method :interior_ring, :interior_ring_n

    def exterior_ring
      cast_geometry_ptr(
        FFIGeos.GEOSGetExteriorRing_r(Geos.current_handle_pointer, self.ptr), {
          :auto_free => false,
          :srid_copy => self.srid,
          :parent => self
        }
      )
    end

    def interior_rings
      self.num_interior_rings.times.collect do |n|
        self.interior_ring_n(n)
      end
    end
  end
end
