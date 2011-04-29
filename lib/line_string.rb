
module Geos
  class LineString < Geometry
    include Enumerable

    def each
      self.num_points.times do |n|
        yield self.point_n(n)
      end
      nil
    end

    if FFIGeos.respond_to?(:GEOSGeomGetNumPoints_r)
      def num_points
        FFIGeos.GEOSGeomGetNumPoints_r(Geos.current_handle, self.ptr)
      end
    else
      def num_points
        self.coord_seq.length
      end
    end

    def point_n(n)
      if n < 0 || n >= self.num_points
        raise RuntimeError.new("Index out of bounds")
      else
        cast_geometry_ptr(FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle, self.ptr, n))
      end
    end

    def [](*args)
      self.to_a[*args]
    end
    alias :slice :[]

    # Deprecated in GEOS 3.3.0. Use Geos::LingString#offset_curve with a
    # negative width instead.
    def buffer_single_sided(width, options = {})
      options = {
        :quad_segs => 8,
        :join => :round,
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

    def offset_curve(width, options = {})
      options = {
        :quad_segs => 8,
        :join => :round,
        :mitre_limit => 5.0,
        :left_side => false
      }.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSOffsetCurve_r(
          Geos.current_handle,
          self.ptr,
          width,
          options[:quad_segs],
          options[:join],
          options[:mitre_limit]
      ))
    end

    if FFIGeos.respond_to?(:GEOSisClosed_r)
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle, self.ptr))
      end
    end
  end
end
