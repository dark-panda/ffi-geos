
module Geos
  class Geometry
    include Geos::Tools

    attr_reader :ptr

    # For internal use. Geometry objects should be created via WkbReader,
    # WktReader and the various Geos.create_* methods.
    def initialize(ptr, auto_free = true)
      @ptr = FFI::AutoPointer.new(
        ptr,
        auto_free ? self.class.method(:release) : self.class.method(:no_release)
      )

      if !auto_free
        @ptr.autorelease = false
      end
    end

    def initialize_copy(source)
      @ptr = FFI::AutoPointer.new(
        FFIGeos.GEOSGeom_clone_r(Geos.current_handle, source.ptr),
        self.class.method(:release)
      )

      # Copy over SRID since GEOS does not
      self.srid = source.srid
    end

    def self.no_release(ptr) #:nodoc:
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSGeom_destroy_r(Geos.current_handle, ptr)
    end

    # Returns the name of the Geometry type, i.e. "Point", "Polygon", etc.
    def geom_type
      FFIGeos.GEOSGeomType_r(Geos.current_handle, self.ptr)
    end

    # Returns one of the values from Geos::GeomTypes.
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

    # :call-seq:
    #   buffer(width)
    #   buffer(width, options)
    #   buffer(width, buffer_params)
    #   buffer(width, quad_segs)
    #
    # Calls buffer on the Geometry. Options can be passed as either a
    # BufferParams object, as an equivalent Hash or as a quad_segs value. By
    # default, the default values found in Geos::Constants::BUFFER_PARAMS_DEFAULTS
    # are used.
    def buffer(width, options = nil)
      options ||= {}
      params = case options
        when Hash
          Geos::BufferParams.new(options)
        when Geos::BufferParams
          options
        when Numeric
          Geos::BufferParams.new(:quad_segs => options)
        else
          raise ArgumentError.new("Expected Geos::BufferParams, a Hash or a Numeric")
      end

      cast_geometry_ptr(FFIGeos.GEOSBufferWithParams_r(Geos.current_handle, self.ptr, params.ptr, width))
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

    # Calling without a geom argument is equivalent to calling unary_union when
    # using GEOS 3.3+ and is equivalent to calling union_cascaded in older
    # versions.
    def union(geom = nil)
      if geom
        check_geometry(geom)
        cast_geometry_ptr(FFIGeos.GEOSUnion_r(Geos.current_handle, self.ptr, geom.ptr))
      else
        if self.respond_to?(:unary_union)
          self.unary_union
        else
          self.union_cascaded
        end
      end
    end

    def union_cascaded
      cast_geometry_ptr(FFIGeos.GEOSUnionCascaded_r(Geos.current_handle, self.ptr))
    end

    if FFIGeos.respond_to?(:GEOSUnaryUnion_r)
      # Available in GEOS 3.3+
      def unary_union
        cast_geometry_ptr(FFIGeos.GEOSUnaryUnion_r(Geos.current_handle, self.ptr))
      end
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

    # Returns the Dimensionally Extended Nine-Intersection Model (DE-9IM)
    # matrix of the geometries as a String.
    def relate(geom)
      check_geometry(geom)
      FFIGeos.GEOSRelate_r(Geos.current_handle, self.ptr, geom.ptr)
    end

    # Checks the DE-9IM pattern against the geoms.
    def relate_pattern(geom, pattern)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSRelatePattern_r(Geos.current_handle, self.ptr, geom.ptr, pattern))
    end

    if FFIGeos.respond_to?(:GEOSRelateBoundaryNodeRule_r)
      # Available in GEOS 3.3+.
      def relate_boundary_node_rule(geom, bnr = :mod2)
        check_geometry(geom)
        check_enum_value(Geos::RelateBoundaryNodeRules, bnr)
        FFIGeos.GEOSRelateBoundaryNodeRule_r(Geos.current_handle, self.ptr, geom.ptr, bnr)
      end
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

    if FFIGeos.respond_to?(:GEOSCovers_r)
      # In GEOS versions 3.3+, the native GEOSCoveredBy method will be used,
      # while in older GEOS versions we'll use a relate_pattern-based
      # implementation.
      def covers?(geom)
        check_geometry(geom)
        bool_result(FFIGeos.GEOSCovers_r(Geos.current_handle, self.ptr, geom.ptr))
      end
    else
      def covers?(geom) #:nodoc:
        check_geometry(geom)
        !!%w{
          T*****FF*
          *T****FF*
          ***T**FF*
          ****T*FF*
        }.detect do |pattern|
          self.relate_pattern(geom, pattern)
        end
      end
    end

    if FFIGeos.respond_to?(:GEOSCoveredBy_r)
      # In GEOS versions 3.3+, the native GEOSCovers method will be used,
      # while in older GEOS versions we'll use a relate_pattern-based
      # implementation.
      def covered_by?(geom)
        check_geometry(geom)
        bool_result(FFIGeos.GEOSCoveredBy_r(Geos.current_handle, self.ptr, geom.ptr))
      end
    else
      def covered_by?(geom) #:nodoc:
        check_geometry(geom)
        !!%w{
          T*F**F***
          *TF**F***
          **FT*F***
          **F*TF***
        }.detect do |pattern|
          self.relate_pattern(geom, pattern)
        end
      end
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

    # Returns a String describing whether or not the Geometry is valid.
    def valid_reason
      FFIGeos.GEOSisValidReason_r(Geos.current_handle, self.ptr)
    end

    # Returns a Hash containing the following structure on invalid geometries:
    #
    #   {
    #     :detail => "String explaining the problem",
    #     :location => Geos::Point # centered on the problem
    #   }
    #
    # If the Geometry is valid, returns nil.
    def valid_detail(flags = 0)
      detail = FFI::MemoryPointer.new(:pointer)
      location = FFI::MemoryPointer.new(:pointer)
      valid = bool_result(
        FFIGeos.GEOSisValidDetail_r(Geos.current_handle, self.ptr, flags, detail, location)
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
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSArea_r(Geos.current_handle, self.ptr, ret)
      }.read_double
    end

    def length
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSLength_r(Geos.current_handle, self.ptr, ret)
      }.read_double
    end

    def distance(geom)
      check_geometry(geom)
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSDistance_r(Geos.current_handle, self.ptr, geom.ptr, ret)
      }.read_double
    end

    def hausdorff_distance(geom, densify_frac = nil)
      check_geometry(geom)
      FFI::MemoryPointer.new(:double).tap { |ret|
        if densify_frac
          FFIGeos.GEOSHausdorffDistanceDensify_r(Geos.current_handle, self.ptr, geom.ptr, densify_frac, ret)
        else
          FFIGeos.GEOSHausdorffDistance_r(Geos.current_handle, self.ptr, geom.ptr, ret)
        end
      }.read_double
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

    # Returns a Hash with the following structure:
    #
    #   {
    #     :rings => [ ... ],
    #     :cuts => [ ... ],
    #     :dangles => [ ... ],
    #     :invalid_rings => [ ... ]
    #   }
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
      Geos::PreparedGeometry.new(self)
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
