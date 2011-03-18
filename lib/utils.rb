
module Geos
  module Utils
    class << self
      include Geos::Tools

      if FFIGeos.respond_to?(:GEOSOrientationIndex_r)
        def orientation_index(ax, ay, bx, by, px, py)
          FFIGeos.GEOSOrientationIndex_r(
            Geos.current_handle,
            ax, ay, bx, by, px, py
          )
        end
      end

      if FFIGeos.respond_to?(:GEOSRelatePatternMatch_r)
        def relate_match(mat, pat)
          bool_result(FFIGeos.GEOSRelatePatternMatch_r(Geos.current_handle, mat, pat))
        end
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

      def create_polygon(outer, *inner)
        inner = Array(inner).flatten.tap { |i|
          if i.detect { |g| !g.is_a?(Geos::LinearRing) }
            raise TypeError.new("Expected inner Array to contain Geometry::LinearRing objects")
          end
        }

        ary = FFI::MemoryPointer.new(:pointer, inner.length)
        ary.write_array_of_pointer(inner.map(&:ptr))

        cast_geometry_ptr(FFIGeos.GEOSGeom_createPolygon_r(Geos.current_handle, outer.ptr, ary, inner.length)).tap {
          outer.ptr.autorelease = false
          inner.each { |i| i.ptr.autorelease = false }
        }
      end

      def create_empty_point
        cast_geometry_ptr(FFIGeos.GEOSGeom_createEmptyPoint_r(Geos.current_handle))
      end

      def create_empty_line_string
        cast_geometry_ptr(FFIGeos.GEOSGeom_createEmptyLineString_r(Geos.current_handle))
      end

      def create_empty_polygon
        cast_geometry_ptr(FFIGeos.GEOSGeom_createEmptyPolygon_r(Geos.current_handle))
      end

      def create_empty_collection(t)
        cast_geometry_ptr(FFIGeos.GEOSGeom_createEmptyCollection_r(Geos.current_handle, t))
      end

      def create_empty_multi_point
        create_empty_collection(Geos::GeomTypes::GEOS_MULTIPOINT)
      end

      def create_empty_multi_line_string
        create_empty_collection(Geos::GeomTypes::GEOS_MULTILINESTRING)
      end

      def create_empty_multi_polygon
        create_empty_collection(Geos::GeomTypes::GEOS_MULTIPOLYGON)
      end

      def create_empty_geometry_collection
        create_empty_collection(Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION)
      end

      def create_collection(t, *geoms)
        klass = case t
          when Geos::GeomTypes::GEOS_MULTIPOINT
            Geos::Point
          when Geos::GeomTypes::GEOS_MULTILINESTRING
            Geos::LineString
          when Geos::GeomTypes::GEOS_MULTIPOLYGON
            Geos::Polygon
          when Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION
            Geos::Geometry
        end

        geoms = Array(geoms).flatten.tap { |i|
          if i.detect { |g| !g.is_a?(klass) }
            raise TypeError.new("Expected geoms Array to contain #{klass} objects")
          end
        }

        ary = FFI::MemoryPointer.new(:pointer, geoms.length)
        ary.write_array_of_pointer(geoms.map(&:ptr))

        cast_geometry_ptr(FFIGeos.GEOSGeom_createCollection_r(Geos.current_handle, t, ary, geoms.length)).tap {
          geoms.each { |i| i.ptr.autorelease = false }
        }
      end

      def create_multi_point(*geoms)
        create_collection(Geos::GeomTypes::GEOS_MULTIPOINT, *geoms)
      end

      def create_multi_line_string(*geoms)
        create_collection(Geos::GeomTypes::GEOS_MULTILINESTRING, *geoms)
      end

      def create_multi_polygon(*geoms)
        create_collection(Geos::GeomTypes::GEOS_MULTIPOLYGON, *geoms)
      end

      def create_geometry_collection(*geoms)
        create_collection(Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION, *geoms)
      end
    end
  end
end
