
module Geos
  module Tools
    include GeomTypes

    def cast_geometry_ptr(geom_ptr, auto_free = true)
      if geom_ptr.null?
        raise RuntimeError.new("Tried to create a Geometry from a NULL pointer!")
      end

      klass = case FFIGeos.GEOSGeomTypeId_r(Geos.current_handle, geom_ptr)
        when GEOS_POINT
          Point
        when GEOS_LINESTRING
          LineString
        when GEOS_LINEARRING
          LinearRing
        when GEOS_POLYGON
          Polygon
        when GEOS_MULTIPOINT
          MultiPoint
        when GEOS_MULTILINESTRING
          MultiLineString
        when GEOS_MULTIPOLYGON
          MultiPolygon
        when GEOS_GEOMETRYCOLLECTION
          GeometryCollection
        else
          raise RuntimeError.new("Invalid geometry type")
      end

      klass.new(geom_ptr, auto_free)
    end

    def check_geometry(geom)
      raise TypeError.new("Expected Geos::Geometry") unless geom.is_a?(Geos::Geometry)
    end

    def bool_result(r)
      case r
      when 1
        true
      when 0
        false
      else
        raise RuntimeError.new("Unexpected boolean result: #{r}")
      end
    end
  end
end
