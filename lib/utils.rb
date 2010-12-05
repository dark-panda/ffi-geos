
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
        if cs.length != 1
          raise RuntimeError.new("IllegalArgumentException: Point coordinate list must contain a single element")
        end

        cast_geometry_ptr(FFIGeos.GEOSGeom_createPoint_r(Geos.current_handle, cs.ptr)).tap {
          cs.ptr.autorelease = false
        }
      end

      def create_line_string(cs)
        if cs.length <= 1 && cs.length != 0
          raise RuntimeError.new("IllegalArgumentException: point array must contain 0 or >1 elements")
        end

        cast_geometry_ptr(FFIGeos.GEOSGeom_createLineString_r(Geos.current_handle, cs.ptr)).tap {
          cs.ptr.autorelease = false
        }
      end

      def create_linear_ring(cs)
        if cs.length <= 1 && cs.length != 0
          raise RuntimeError.new("IllegalArgumentException: point array must contain 0 or >1 elements")
        end

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

        ary = FFI::MemoryPointer.new(:pointer, inner.length)
        ary.write_array_of_pointer(inner.map(&:ptr))

        cast_geometry_ptr(FFIGeos.GEOSGeom_createPolygon_r(Geos.current_handle, outer.ptr, ary, inner.length)).tap {
          outer.ptr.autorelease = false
          if !inner.empty?
            inner.each { |i| i.ptr.autorelease = false }
          end
        }
      end
    end
  end
end
