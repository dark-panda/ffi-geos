# encoding: UTF-8

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
        num_geometries.times.collect do |n|
          get_geometry_n(n)
        end.to_enum
      end
    end

    def get_geometry_n(n)
      if n < 0 || n >= num_geometries
        nil
      else
        cast_geometry_ptr(FFIGeos.GEOSGetGeometryN_r(Geos.current_handle, ptr, n), auto_free: false)
      end
    end
    alias_method :geometry_n, :get_geometry_n

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        get_geometry_n(args.first)
      else
        to_a[*args]
      end
    end
    alias_method :slice, :[]
    alias_method :at, :[]
  end
end
