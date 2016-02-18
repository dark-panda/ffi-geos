# encoding: UTF-8

module Geos
  class Polygon < Geometry
    def num_interior_rings
      FFIGeos.GEOSGetNumInteriorRings_r(Geos.current_handle, ptr)
    end

    def interior_ring_n(n)
      if n < 0 || n >= num_interior_rings
        fail Geos::IndexBoundsError.new
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGetInteriorRingN_r(Geos.current_handle, ptr, n),             auto_free: false,
                                                                                   srid_copy: srid,
                                                                                   parent: self
        )
      end
    end
    alias_method :interior_ring, :interior_ring_n

    def exterior_ring
      cast_geometry_ptr(
        FFIGeos.GEOSGetExteriorRing_r(Geos.current_handle, ptr),           auto_free: false,
                                                                           srid_copy: srid,
                                                                           parent: self
      )
    end

    def interior_rings
      num_interior_rings.times.collect do |n|
        interior_ring_n(n)
      end
    end
  end
end
