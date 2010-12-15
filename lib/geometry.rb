
module Geos
  class Geometry
    include Geos::Tools

    attr_reader :ptr

    def initialize(ptr, auto_free = true)
      @ptr = FFI::AutoPointer.new(
        ptr,
        auto_free ? self.class.method(:release) : self.class.method(:no_release)
      )
    end

    def self.no_release(ptr) #:nodoc:
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSGeom_destroy_r(Geos.current_handle, ptr)
    end

    def clone
      cast_geometry_ptr(FFIGeos.GEOSGeom_clone_r(Geos.current_handle, ptr))
    end

    def geom_type
      FFIGeos.GEOSGeomType_r(Geos.current_handle, self.ptr)
    end

    def type_id
      FFIGeos.GEOSGeomTypeId_r(Geos.current_handle, self.ptr)
    end

    def normalize
      FFIGeos.GEOSNormalize_r(Geos.current_handle, self.ptr)
    end

    def srid
      FFIGeos.GEOSGetSRID_r(Geos.current_handle, self.ptr)
    end

    def srid=(s)
      FFIGeos.GEOSSetSRID_r(Geos.current_handle, self.ptr, s)
    end

    def dimensions
      FFIGeos.GEOSGeom_getDimensions_r(Geos.current_handle, self.ptr)
    end

    def num_geometries
      FFIGeos.GEOSGetNumGeometries_r(Geos.current_handle, self.ptr)
    end

    def num_coordinates
      FFIGeos.GEOSGetNumCoordinates_r(Geos.current_handle, self.ptr)
    end

    def coord_seq
      CoordinateSequence.new(FFIGeos.GEOSGeom_getCoordSeq_r(Geos.current_handle, self.ptr), false)
    end

    def intersection(geom)
      check_geometry(geom)
      cast_geometry_ptr(FFIGeos.GEOSIntersection_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def buffer(width, *args)
      quad_segs, options = if args.length <= 0
        [ 8, nil ]
      else
        if args.first.is_a?(Hash)
          [ args.first[:quad_segs] || 8, args.first ]
        else
          [ args.first, args[1] ]
        end
      end

      if options
        if options.is_a?(Hash)
          self.buffer_with_style(width, options)
        else
          raise RuntimeError.new("Expected an options Hash")
        end
      else
        cast_geometry_ptr(FFIGeos.GEOSBuffer_r(Geos.current_handle, self.ptr, width, quad_segs))
      end
    end

    def buffer_with_style(width, options = {})
      options = {
        :quad_segs => 8,
        :endcap => Geos::BufferCapStyles::ROUND,
        :join => Geos::BufferJoinStyles::ROUND,
        :mitre_limit => 5.0
      }.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSBufferWithStyle_r(
          Geos.current_handle,
          self.ptr,
          width,
          options[:quad_segs],
          options[:endcap],
          options[:join],
          options[:mitre_limit]
      ))
    end

    def convex_hull
      cast_geometry_ptr(FFIGeos.GEOSConvexHull_r(Geos.current_handle, self.ptr))
    end

    def difference(geom)
      check_geometry(geom)
      cast_geometry_ptr(FFIGeos.GEOSDifference_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def sym_difference(geom)
      check_geometry(geom)
      cast_geometry_ptr(FFIGeos.GEOSSymDifference_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def boundary
      cast_geometry_ptr(FFIGeos.GEOSBoundary_r(Geos.current_handle, self.ptr))
    end

    def union(geom = nil)
      if geom
        check_geometry(geom)
        cast_geometry_ptr(FFIGeos.GEOSUnion_r(Geos.current_handle, self.ptr, geom.ptr))
      else
        self.union_cascaded
      end
    end

    def union_cascaded
      cast_geometry_ptr(FFIGeos.GEOSUnionCascaded_r(Geos.current_handle, self.ptr))
    end

    def point_on_surface
      cast_geometry_ptr(FFIGeos.GEOSPointOnSurface_r(Geos.current_handle, self.ptr))
    end

    def centroid
      cast_geometry_ptr(FFIGeos.GEOSGetCentroid_r(Geos.current_handle, self.ptr))
    end
    alias :center :centroid

    def envelope
      cast_geometry_ptr(FFIGeos.GEOSEnvelope_r(Geos.current_handle, self.ptr))
    end

    def relate(geom)
      check_geometry(geom)
      FFIGeos.GEOSRelate_r(Geos.current_handle, self.ptr, geom.ptr)
    end

    def relate_pattern(geom, pattern)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSRelatePattern_r(Geos.current_handle, self.ptr, geom.ptr, pattern))
    end

    def line_merge
      cast_geometry_ptr(FFIGeos.GEOSLineMerge_r(Geos.current_handle, self.ptr))
    end

    def simplify(tolerance)
      cast_geometry_ptr(FFIGeos.GEOSSimplify_r(Geos.current_handle, self.ptr, tolerance))
    end

    def topology_preserve_simplify(tolerance)
      cast_geometry_ptr(FFIGeos.GEOSTopologyPreserveSimplify_r(Geos.current_handle, self.ptr, tolerance))
    end

    def extract_unique_points
      cast_geometry_ptr(FFIGeos.GEOSGeom_extractUniquePoints_r(Geos.current_handle, self.ptr))
    end
    alias :unique_points :extract_unique_points

    def disjoint?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSDisjoint_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def touches?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSTouches_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def intersects?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSIntersects_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def crosses?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSCrosses_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def within?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSWithin_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def contains?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSContains_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def overlaps?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSOverlaps_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def disjoint?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSDisjoint_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def eql?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSEquals_r(Geos.current_handle, self.ptr, geom.ptr))
    end
    alias :== :eql?

    def eql_exact?(geom, tolerance)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSEqualsExact_r(Geos.current_handle, self.ptr, geom.ptr, tolerance))
    end

    def empty?
      bool_result(FFIGeos.GEOSisEmpty_r(Geos.current_handle, self.ptr))
    end

    def valid?
      bool_result(FFIGeos.GEOSisValid_r(Geos.current_handle, self.ptr))
    end

    def valid_reason
      FFIGeos.GEOSisValidReason_r(Geos.current_handle, self.ptr)
    end

    def valid_detail
      detail = FFI::MemoryPointer.new(:pointer)
      location = FFI::MemoryPointer.new(:pointer)
      valid = bool_result(
        FFIGeos.GEOSisValidDetail_r(Geos.current_handle, self.ptr, detail, location)
      )

      if !valid
        {
          :detail => detail.read_pointer.read_string,
          :location => cast_geometry_ptr(location.read_pointer)
        }
      end
    end

    def simple?
      bool_result(FFIGeos.GEOSisSimple_r(Geos.current_handle, self.ptr))
    end

    def ring?
      bool_result(FFIGeos.GEOSisRing_r(Geos.current_handle, self.ptr))
    end

    def has_z?
      bool_result(FFIGeos.GEOSHasZ_r(Geos.current_handle, self.ptr))
    end

    # GEOS versions prior to 3.3.0 didn't handle exceptions and can crash on
    # bad input.
    if FFIGeos.respond_to?(:GEOSProject_r) && Geos::GEOS_VERSION >= '3.3.0'
      def project(geom, normalized = false)
        raise TypeError.new("Expected Geos::Point type") if !geom.is_a?(Geos::Point)

        if normalized
          FFIGeos.GEOSProjectNormalized_r(Geos.current_handle, self.ptr, geom.ptr)
        else
          FFIGeos.GEOSProject_r(Geos.current_handle, self.ptr, geom.ptr)
        end
      end

      def project_normalized(geom)
        self.project(geom, true)
      end
    end

    def interpolate(d, normalized = false)
      ret = if normalized
        FFIGeos.GEOSInterpolateNormalized_r(Geos.current_handle, self.ptr, d)
      else
        FFIGeos.GEOSInterpolate_r(Geos.current_handle, self.ptr, d)
      end

      cast_geometry_ptr(ret)
    end

    def interpolate_normalized(d)
      self.interpolate(d, true)
    end

    def start_point
      cast_geometry_ptr(FFIGeos.GEOSGeomGetStartPoint_r(Geos.current_handle, self.ptr))
    end

    def end_point
      cast_geometry_ptr(FFIGeos.GEOSGeomGetEndPoint_r(Geos.current_handle, self.ptr))
    end

    def area
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSArea_r(Geos.current_handle, self.ptr, ret)
      }.get_double(0)
    end

    def length
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSLength_r(Geos.current_handle, self.ptr, ret)
      }.get_double(0)
    end

    def distance(geom)
      check_geometry(geom)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSDistance_r(Geos.current_handle, self.ptr, geom.ptr, ret)
      }.get_double(0)
    end

    def hausdorff_distance(geom)
      check_geometry(geom)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSHausdorffDistance_r(Geos.current_handle, self.ptr, geom.ptr, ret)
      }.get_double(0)
    end

    def snap(geom, tolerance)
      check_geometry(geom)
      cast_geometry_ptr(FFIGeos.GEOSSnap_r(Geos.current_handle, self.ptr, geom.ptr, tolerance))
    end
    alias :snap_to :snap

    def shared_paths(geom)
      check_geometry(geom)
      cast_geometry_ptr(FFIGeos.GEOSSharedPaths_r(Geos.current_handle, self.ptr, geom.ptr)).to_a
    end

    def polygonize_full
      cuts = FFI::MemoryPointer.new(:pointer)
      dangles = FFI::MemoryPointer.new(:pointer)
      invalid_rings = FFI::MemoryPointer.new(:pointer)

      rings = cast_geometry_ptr(
        FFIGeos.GEOSPolygonize_full_r(Geos.current_handle, self.ptr, cuts, dangles, invalid_rings)
      )

      cuts = cast_geometry_ptr(cuts.read_pointer)
      dangles = cast_geometry_ptr(dangles.read_pointer)
      invalid_rings = cast_geometry_ptr(invalid_rings.read_pointer)

      {
        :rings => rings.to_a,
        :cuts => cuts.to_a,
        :dangles => dangles.to_a,
        :invalid_rings => invalid_rings.to_a
      }
    end

    def polygonize
      ary = FFI::MemoryPointer.new(:pointer)
      ary.write_array_of_pointer([ self.ptr ])

      cast_geometry_ptr(FFIGeos.GEOSPolygonize_r(Geos.current_handle, ary, 1)).to_a
    end

    def polygonize_cut_edges
      ary = FFI::MemoryPointer.new(:pointer)
      ary.write_array_of_pointer([ self.ptr ])

      cast_geometry_ptr(FFIGeos.GEOSPolygonizer_getCutEdges_r(Geos.current_handle, ary, 1)).to_a
    end

    def to_prepared
      Geos::PreparedGeometry.new(FFIGeos.GEOSPrepare_r(Geos.current_handle, self.ptr))
    end

    def to_s
      writer = WktWriter.new
      wkt = writer.write(self)
      if wkt.length > 120
        wkt = "#{wkt[0...120]} ... "
      end

      "#<Geos::#{self.geom_type}: #{wkt}>"
    end
  end
end
