# encoding: UTF-8
# frozen_string_literal: true

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
        raise Geos::IndexBoundsError.new
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle, self.ptr, n), {
            :srid_copy => self.srid
          }
        )
      end
    end

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        self.point_n(args.first)
      else
        self.to_a[*args]
      end
    end
    alias_method :slice, :[]

    def offset_curve(width, options = {})
      options = Constants::BUFFER_PARAM_DEFAULTS.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSOffsetCurve_r(
          Geos.current_handle,
          self.ptr,
          width,
          options[:quad_segs],
          options[:join],
          options[:mitre_limit]
      ), {
        :srid_copy => self.srid
      })
    end

    if FFIGeos.respond_to?(:GEOSisClosed_r)
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle, self.ptr))
      end
    end

    def to_linear_ring
      if self.closed?
        Geos.create_linear_ring(self.coord_seq, :srid => pick_srid_according_to_policy(self.srid))
      else
        self_cs = self.coord_seq.to_a
        self_cs.push(self_cs[0])

        Geos.create_linear_ring(self_cs, :srid => pick_srid_according_to_policy(self.srid))
      end
    end

    def to_polygon
      self.to_linear_ring.to_polygon
    end
  end
end
