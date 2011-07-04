
module Geos
  class LineString < Geometry
    include Enumerable

    def each
      if block_given?
        self.num_points.times do |n|
          yield self.point_n(n)
        end
        self
      else
        self.num_points.times.collect { |n|
          self.point_n(n)
        }.to_enum
      end
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

    def offset_curve(width, options = {})
      options = Constants::BUFFER_PARAM_DEFAULTS.merge(options)

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
