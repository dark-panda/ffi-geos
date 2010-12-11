
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

    def buffer_single_sided(width, options = {})
      options = {
        :quad_segs => 8,
        :join => Geos::BufferJoinStyles::ROUND,
        :mitre_limit => 5.0,
        :left_side => false
      }.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSSingleSidedBuffer_r(
          Geos.current_handle,
          self.ptr,
          width,
          options[:quad_segs],
          options[:join],
          options[:mitre_limit],
          options[:left_side] ? 1 : 0
      ))
    end
  end
end
