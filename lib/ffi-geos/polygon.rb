
module Geos
  class Polygon < Geometry
    def num_interior_rings
      FFIGeos.GEOSGetNumInteriorRings_r(Geos.current_handle, self.ptr)
    end

    def interior_ring_n(n)
      if n < 0 || n >= self.num_interior_rings
        raise RuntimeError.new("Index out of bounds")
      else
        cast_geometry_ptr(FFIGeos.GEOSGetInteriorRingN_r(Geos.current_handle, self.ptr, n), false)
      end
    end

    def exterior_ring
      cast_geometry_ptr(FFIGeos.GEOSGetExteriorRing_r(Geos.current_handle, self.ptr), false)
    end

    def interior_rings
      self.num_interior_rings.times.collect do |n|
        self.interior_ring_n(n)
      end
    end
  end
end
