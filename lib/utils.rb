
module Geos
  module Utils
    class << self
      include Geos::Tools
      include Geos::GeomTypes

      if FFIGeos.respond_to?(:GEOSOrientationIndex_r)
        # * -1 if reaching P takes a counter-clockwise (left) turn
        # * 1 if reaching P takes a clockwise (right) turn
        # * 0 if P is collinear with A-B
        #
        # Available in GEOS 3.3.0+.
        def orientation_index(ax, ay, bx, by, px, py)
          FFIGeos.GEOSOrientationIndex_r(
            Geos.current_handle,
            ax, ay, bx, by, px, py
          )
        end
      end

      if FFIGeos.respond_to?(:GEOSRelatePatternMatch_r)
        # Available in GEOS 3.3.0+.
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
        check_enum_value(Geos::GeometryTypes, t)
        cast_geometry_ptr(FFIGeos.GEOSGeom_createEmptyCollection_r(Geos.current_handle, t))
      end

      def create_empty_multi_point
        create_empty_collection(:multi_point)
      end

      def create_empty_multi_line_string
        create_empty_collection(:multi_line_string)
      end

      def create_empty_multi_polygon
        create_empty_collection(:multi_polygon)
      end

      def create_empty_geometry_collection
        create_empty_collection(:geometry_collection)
      end

      def create_collection(t, *geoms)
        check_enum_value(Geos::GeometryTypes, t)

        klass = case t
          when GEOS_MULTIPOINT, :multi_point
            Geos::Point
          when GEOS_MULTILINESTRING, :multi_line_string
            Geos::LineString
          when GEOS_MULTIPOLYGON, :multi_polygon
            Geos::Polygon
          when GEOS_GEOMETRYCOLLECTION, :geometry_collection
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
        create_collection(:multi_point, *geoms)
      end

      def create_multi_line_string(*geoms)
        create_collection(:multi_line_string, *geoms)
      end

      def create_multi_polygon(*geoms)
        create_collection(:multi_polygon, *geoms)
      end

      def create_geometry_collection(*geoms)
        create_collection(:geometry_collection, *geoms)
      end
    end
  end
end
