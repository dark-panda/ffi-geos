
module Geos
  class LineString < Geometry
    def num_points
      FFIGeos.GEOSGeomGetNumPoints_r(Geos.current_handle, self.ptr)
    end

    def point_n(n)
      if n < 0 || n >= self.num_points
        raise RuntimeError.new("Index out of bounds")
      else
        cast_geometry_ptr(FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle, self.ptr, n))
      end
    end
  end
end
