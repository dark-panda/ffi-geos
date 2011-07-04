
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
        cast_geometry_ptr(FFIGeos.GEOSGetGeometryN_r(Geos.current_handle, self.ptr, n), false)
      end
    end
    alias :geometry_n :get_geometry_n

    def [](*args)
      self.to_a[*args]
    end
    alias :slice :[]
    alias :at :[]
  end
end
