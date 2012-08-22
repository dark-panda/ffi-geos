# frozen_string_literal: true

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
        num_points.times.collect { |n|
          point_n(n)
        }.to_enum
      end
    end

    if FFIGeos.respond_to?(:GEOSGeomGetNumPoints_r)
      def num_points
        FFIGeos.GEOSGeomGetNumPoints_r(Geos.current_handle_pointer, ptr)
      end
    else
      def num_points
        coord_seq.length
      end
    end

    def point_n(n)
      raise Geos::IndexBoundsError if n < 0 || n >= num_points

      cast_geometry_ptr(FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle_pointer, ptr, n), srid_copy: srid)
    end

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        point_n(args.first)
      else
        to_a[*args]
      end
    end
    alias slice []

    def offset_curve(width, options = {})
      options = Constants::BUFFER_PARAM_DEFAULTS.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSOffsetCurve_r(
        Geos.current_handle_pointer,
        ptr,
        width,
        options[:quad_segs],
        options[:join],
        options[:mitre_limit]
      ), srid_copy: srid)
    end

    if FFIGeos.respond_to?(:GEOSisClosed_r)
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle_pointer, ptr))
      end
    end

    def to_linear_ring
      return Geos.create_linear_ring(coord_seq, srid: pick_srid_according_to_policy(srid)) if closed?

      self_cs = coord_seq.to_a
      self_cs.push(self_cs[0])

      Geos.create_linear_ring(self_cs, srid: pick_srid_according_to_policy(srid))
    end

    def to_polygon
      to_linear_ring.to_polygon
    end

    def dump_points(cur_path = [])
      cur_path.concat(to_a)
    end

    %w{ max min }.each do |op|
      %w{ x y }.each do |dimension|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.coord_seq.#{dimension}_#{op}
            end
          end
        EOF
      end

      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def z_#{op}
          unless self.empty?
            if self.has_z?
              self.coord_seq.z_#{op}
            else
              0
            end
          end
        end
      EOF
    end
  end
end
