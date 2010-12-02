
module Geos
  class GeometryCollection < Geometry
    include Enumerable

    def each
      self.num_geometries.times do |n|
        yield self.get_geometry_n(n)
      end
      nil
    end

    def get_geometry_n(n)
      if n < 0 || n >= self.num_geometries
        nil
      else
        cast_geometry_ptr(FFIGeos.GEOSGetGeometryN_r(Geos.current_handle, self.ptr, n), false)
      end
    end
  end
end
