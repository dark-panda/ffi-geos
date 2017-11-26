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
  end
end
