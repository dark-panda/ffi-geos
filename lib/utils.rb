
module Geos
  module Utils
    class << self
      include Geos::Tools

      def orientation_index(ax, ay, bx, by, px, py)
        FFIGeos.GEOSOrientationIndex_r(
          Geos.current_handle,
          ax, ay, bx, by, px, py
        )
      end

      def create_point(cs)
        cast_geometry_ptr(FFIGeos.GEOSGeom_createPoint_r(Geos.current_handle, cs.ptr)).tap {
          cs.ptr.autorelease = false
        }
      end

      def create_line_string(cs)
        cast_geometry_ptr(FFIGeos.GEOSGeom_createLineString_r(Geos.current_handle, cs.ptr)).tap {
          cs.ptr.autorelease = false
        }
      end

      def create_linear_ring(cs)
        cast_geometry_ptr(FFIGeos.GEOSGeom_createLinearRing_r(Geos.current_handle, cs.ptr)).tap {
          cs.ptr.autorelease = false
        }
      end

      def create_polygon(outer, inner = nil)
        inner = if inner
          Array(inner).tap { |i|
            if i.detect { |g| !g.is_a?(Geos::LinearRing) }
              raise TypeError.new("Expected inner Array to contain Geometry::LinearRing objects")
            end
          }
        else
          []
        end

        ary = FFI::MemoryPointer.new(:pointer)
        ary.write_array_of_pointer(inner.map(&:ptr))

        cast_geometry_ptr(FFIGeos.GEOSGeom_createPolygon_r(Geos.current_handle, outer.ptr, ary, inner.length)).tap {
          outer.ptr.autorelease = false
        }
      end
    end
  end
end
