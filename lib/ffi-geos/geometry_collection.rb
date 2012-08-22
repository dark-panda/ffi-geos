# frozen_string_literal: true

module Geos
  class GeometryCollection < Geometry
    include Enumerable

    # Yields each Geometry in the GeometryCollection.
    def each
      if block_given?
        num_geometries.times do |n|
          yield get_geometry_n(n)
        end
        self
      else
        num_geometries.times.collect { |n|
          get_geometry_n(n)
        }.to_enum
      end
    end

    def get_geometry_n(n)
      if n.negative? || n >= num_geometries
        nil
      else
        cast_geometry_ptr(FFIGeos.GEOSGetGeometryN_r(Geos.current_handle_pointer, ptr, n), auto_free: false)
      end
    end
    alias geometry_n get_geometry_n

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        get_geometry_n(args.first)
      else
        to_a[*args]
      end
    end
    alias slice []
    alias at []

    def dump_points(cur_path = [])
      each do |geom|
        cur_path << geom.dump_points
      end
      cur_path
    end

    %w{ x y z }.each do |dimension|
      %w{ max min }.each do |op|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.collect(&:#{dimension}_#{op}).#{op}
            end
          end
        EOF
      end
    end
  end
end
