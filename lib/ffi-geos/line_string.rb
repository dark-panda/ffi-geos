# encoding: UTF-8

module Geos
  class LineString < Geometry
    include Enumerable

    def each
      if block_given?
        num_points.times do |n|
          yield point_n(n)
        end
        self
      else
        num_points.times.collect do |n|
          point_n(n)
        end.to_enum
      end
    end

    if FFIGeos.respond_to?(:GEOSGeomGetNumPoints_r)
      def num_points
        FFIGeos.GEOSGeomGetNumPoints_r(Geos.current_handle, ptr)
      end
    else
      def num_points
        coord_seq.length
      end
    end

    def point_n(n)
      if n < 0 || n >= num_points
        fail Geos::IndexBoundsError.new
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle, ptr, n), srid_copy: srid
        )
      end
    end

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        point_n(args.first)
      else
        to_a[*args]
      end
    end
    alias_method :slice, :[]

    def offset_curve(width, options = {})
      options = Constants::BUFFER_PARAM_DEFAULTS.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSOffsetCurve_r(
                          Geos.current_handle,
                          ptr,
                          width,
                          options[:quad_segs],
                          options[:join],
                          options[:mitre_limit]
      ), srid_copy: srid)
    end

    if FFIGeos.respond_to?(:GEOSisClosed_r)
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle, ptr))
      end
    end

    def to_linear_ring
      if self.closed?
        Geos.create_linear_ring(coord_seq, srid: pick_srid_according_to_policy(srid))
      else
        self_cs = coord_seq.to_a
        self_cs.push(self_cs[0])

        Geos.create_linear_ring(self_cs, srid: pick_srid_according_to_policy(srid))
      end
    end

    def to_polygon
      to_linear_ring.to_polygon
    end
  end
end
