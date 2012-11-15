# encoding: UTF-8

module Geos
  module Tools
    include GeomTypes

    def cast_geometry_ptr(geom_ptr, options = {})
      options = {
        :auto_free => true
      }.merge(options)

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

      klass.new(geom_ptr, options[:auto_free]).tap { |ret|
        if options[:srid]
          ret.srid = options[:srid] || 0
        elsif options[:srid_copy]
          ret.srid = if Geos.srid_copy_policy == :zero
            0
          else
            options[:srid_copy] || 0
          end
        end
      }
    end

    def check_geometry(geom)
      raise TypeError.new("Expected Geos::Geometry") unless geom.is_a?(Geos::Geometry)
    end

    def pick_srid_from_geoms(srid_a, srid_b, policy = Geos.srid_copy_policy)
      case policy
        when :zero
          0
        when :lenient
          srid_a
        when :strict
          raise Geos::MixedSRIDsError.new(srid_a, srid_b)
      end
    end

    def pick_srid_according_to_policy(srid, policy = Geos.srid_copy_policy)
      if srid != 0 && Geos.srid_copy_policy != :zero
        self.srid
      else
        0
      end
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

    def check_enum_value(enum, value)
      raise TypeError.new("Couldn't find valid #{enum.tag} value: #{value}") unless enum[value]
    end

    def symbol_for_enum(enum, value)
      if value.is_a?(Symbol)
        value
      else
        enum[value]
      end
    end
  end
end
