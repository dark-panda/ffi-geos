# frozen_string_literal: true

module Geos
  class GeometryCollection < Geometry
    include Enumerable

    # Yields each Geometry in the GeometryCollection.
    def each
      if block_given?
        self.num_geometries.times do |n|
          yield self.get_geometry_n(n)
        end
        self
      else
        self.num_geometries.times.collect { |n|
          self.get_geometry_n(n)
        }.to_enum
      end
    end

    def get_geometry_n(n)
      if n < 0 || n >= self.num_geometries
        nil
      else
        cast_geometry_ptr(FFIGeos.GEOSGetGeometryN_r(Geos.current_handle_pointer, self.ptr, n), :auto_free => false)
      end
    end
    alias_method :geometry_n, :get_geometry_n

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        self.get_geometry_n(args.first)
      else
        self.to_a[*args]
      end
    end
    alias_method :slice, :[]
    alias_method :at, :[]
  end
end
