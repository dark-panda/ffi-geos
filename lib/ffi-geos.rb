
require 'ffi'
require 'rbconfig'

module Geos
  GEOS_BASE = File.dirname(__FILE__)

  autoload :WktReader,
    File.join(GEOS_BASE, 'wkt_reader')
  autoload :WktWriter,
    File.join(GEOS_BASE, 'wkt_writer')
  autoload :WkbReader,
    File.join(GEOS_BASE, 'wkb_reader')
  autoload :WkbWriter,
    File.join(GEOS_BASE, 'wkb_writer')
  autoload :CoordinateSequence,
    File.join(GEOS_BASE, 'coordinate_sequence')
  autoload :Geometry,
    File.join(GEOS_BASE, 'geometry')
  autoload :PreparedGeometry,
    File.join(GEOS_BASE, 'prepared_geometry')
  autoload :GeometryCollection,
    File.join(GEOS_BASE, 'geometry_collection')
  autoload :LineString,
    File.join(GEOS_BASE, 'line_string')
  autoload :LinearRing,
    File.join(GEOS_BASE, 'linear_ring')
  autoload :MultiLineString,
    File.join(GEOS_BASE, 'multi_line_string')
  autoload :MultiPoint,
    File.join(GEOS_BASE, 'multi_point')
  autoload :MultiPolygon,
    File.join(GEOS_BASE, 'multi_polygon')
  autoload :Polygon,
    File.join(GEOS_BASE, 'polygon')
  autoload :Point,
    File.join(GEOS_BASE, 'point')
  autoload :STRtree,
    File.join(GEOS_BASE, 'strtree')
  autoload :Tools,
    File.join(GEOS_BASE, 'tools')
  autoload :Utils,
    File.join(GEOS_BASE, 'utils')

  module FFIGeos
    def self.geos_library_paths
      return @geos_library_paths if @geos_library_paths

      paths = if ENV['GEOS_LIBRARY_PATH']
        [ ENV['GEOS_LIBRARY_PATH'] ]
      else
        [ '/usr/local/{lib64,lib}', '/opt/local/{lib64,lib}', '/usr/{lib64,lib}' ]
      end

      libs = if [
        Config::CONFIG['arch'],
        Config::CONFIG['host_os']
      ].detect { |c| c =~ /darwin/ }
        %w{ libgeos_c.dylib libgeos.dylib }
      else
        %w{ libgeos.so libgeos_c.so }
      end

      @geos_library_paths = libs.collect { |lib|
        Dir.glob(paths.collect { |path|
          "#{path}/#{lib}"
        }).first
      }
    end

    extend ::FFI::Library

    ffi_lib(*geos_library_paths)

    Geos::DimensionTypes = enum(:dimension_type, [
      :dontcare, -3,
      :non_empty, -2,
      :empty, -1,
      :point, 0,
      :curve, 1,
      :surface, 2
    ])

    Geos::ByteOrders = enum(:byte_order, [
      :xdr, 0, # Big Endian
      :ndr, 1 # Little Endian
    ])

    Geos::BufferCapStyles = enum(:buffer_cap_style, [
      :round, 1,
      :flat, 2,
      :square, 3
    ])

    Geos::BufferJoinStyles = enum(:buffer_join_style, [
      :round, 1,
      :mitre, 2,
      :bevel, 3
    ])

    Geos::ValidFlags = enum(:valid_flag, [
      :allow_selftouching_ring_forming_hole, 1
    ])

    Geos::RelateBoundaryNodeRules = enum(:relate_boundary_node_rule, [
      :mod2, 1,
      :ogc, 1,
      :endpoint, 2,
      :multivalent_endpoint, 3,
      :monovalent_endpoint, 4
    ])

    FFI_LAYOUT = {
      #### Utility functions ####
      :initGEOS_r => [
        :pointer,

        # notice callback
        callback([ :string, :string ], :void),

        # error callback
        callback([ :string, :string ], :void)
      ],

      :finishGEOS_r => [
        # void, *handle
        :void, :pointer
      ],

      :GEOSversion => [
        :string
      ],

      :GEOSjtsport => [
        :string
      ],

      :GEOSPolygonize_r => [
        # *geom, *handle, *geom_a, *geom_b, ngeoms
        :pointer, :pointer, :pointer, :uint
      ],

      :GEOSPolygonizer_getCutEdges_r => [
        # *(geom, *handle, *geoms[], ngeoms
        :pointer, :pointer, :pointer, :uint
      ],

      :GEOSPolygonize_full_r => [
        # *geom, *handle, *geom, **cuts, **dangles, **invalid
        :pointer, :pointer, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSGeom_createPoint_r => [
        # *geom, *handle, *coord_seq
        :pointer, :pointer, :pointer
      ],

      :GEOSGeom_createEmptyPoint_r => [
        # *geom, *handle
        :pointer, :pointer
      ],

      :GEOSGeom_createEmptyLineString_r => [
        # *geom, *handle
        :pointer, :pointer
      ],

      :GEOSGeom_createLinearRing_r => [
        # *geom, *handle, *coord_seq
        :pointer, :pointer, :pointer
      ],

      :GEOSGeom_createLineString_r => [
        # *geom, *handle, *coord_seq
        :pointer, :pointer, :pointer
      ],

      :GEOSGeom_createPolygon_r => [
        # *geom, *handle, *geom, **holes, nholes
        :pointer, :pointer, :pointer, :pointer, :uint
      ],

      :GEOSGeom_createEmptyPolygon_r => [
        # *geom, *handle
        :pointer, :pointer
      ],

      :GEOSGeom_createCollection_r => [
        # *geom, *handle, type, **geoms, ngeoms
        :pointer, :pointer, :int, :pointer, :uint
      ],

      :GEOSGeom_createEmptyCollection_r => [
        # *geom, *handle, type
        :pointer, :pointer, :int
      ],
      #### /Utility functions ####

      #### CoordinateSequence functions ####
      :GEOSCoordSeq_create_r => [
        # *coord_seq, *handle, size, dims
        :pointer, :pointer, :uint, :uint
      ],

      :GEOSCoordSeq_destroy_r => [
        # void, *handle, *coord_seq
        :void, :pointer, :pointer
      ],

      :GEOSCoordSeq_clone_r => [
        # *coord_seq, *handle, *coord_seq
        :pointer, :pointer, :pointer
      ],

      :GEOSCoordSeq_setX_r => [
        # 0 on exception, *handle, *coord_seq, idx, val
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setY_r => [
        # 0 on exception, *handle, *coord_seq, idx, val
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setZ_r => [
        # 0 on exception, *handle, *coord_seq, idx, val
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setOrdinate_r => [
        # 0 on exception, *handle, *coord_seq, idx, dim, val
        :int, :pointer, :pointer, :uint, :uint, :double
      ],

      :GEOSCoordSeq_getX_r => [
        # 0 on exception, *handle, *coord_seq, idx, (double *) val
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getY_r => [
        # 0 on exception, *handle, *coord_seq, idx, (double *) val
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getZ_r => [
        # 0 on exception, *handle, *coord_seq, idx, (double *) val
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getOrdinate_r => [
        # 0 on exception, *handle, *coord_seq, idx, dim, (double *) val
        :int, :pointer, :pointer, :uint, :uint, :pointer
      ],

      :GEOSCoordSeq_getSize_r => [
        # 0 on exception, *handle, *coord_seq, (uint *) size
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSCoordSeq_getDimensions_r => [
        # 0 on exception, *handle, *coord_seq, (uint *) size
        :int, :pointer, :pointer, :pointer
      ],
      #### /CoordinateSequence functions ####

      #### Geometry functions ####
      :GEOSGeom_destroy_r => [
        # void, *handle, *geom
        :void, :pointer, :pointer
      ],

      :GEOSGeom_clone_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomTypeId_r => [
        # type, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGeomType_r => [
        # type, *handle, *geom
        :string, :pointer, :pointer
      ],

      :GEOSGetSRID_r => [
        # srid, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSSetSRID_r => [
        # void, *handle, *geom, srid
        :void, :pointer, :pointer, :int
      ],

      :GEOSGeom_getDimensions_r => [
        # dims, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGetNumGeometries_r => [
        # ngeoms, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGetNumCoordinates_r => [
        # numcoords, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGeom_getCoordSeq_r => [
        # *coord_seq, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSIntersection_r => [
        # *geom, *handle, *geom_a, *geom_b
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSBuffer_r => [
        # *geom, *handle, *geom, width, quad_segs
        :pointer, :pointer, :pointer, :double, :int
      ],

      :GEOSBufferWithStyle_r => [
        # *geom, *handle, *geom, width, quad_segs, buffer_cap_style, buffer_join_style, mitre_limit
        :pointer, :pointer, :pointer, :double, :int, :buffer_cap_style, :buffer_join_style, :double
      ],

      # Deprecated in GEOS 3.3.0.
      :GEOSSingleSidedBuffer_r => [
        # *geom, *handle, *geom, width, quad_segs, buffer_join_style, mitre_limit, is_left
        :pointer, :pointer, :pointer, :double, :int, :buffer_join_style, :double, :int
      ],

      :GEOSOffsetCurve_r => [
        # *geom, *handle, *geom, width, quad_segs, buffer_join_style, mitre_limit
        :pointer, :pointer, :pointer, :double, :int, :buffer_join_style, :double
      ],

      :GEOSConvexHull_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSDifference_r => [
        # *geom, *handle, *geom_a, *geom_b
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSymDifference_r => [
        # *geom, *handle, *geom_a, *geom_b
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSBoundary_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSUnion_r => [
        # *geom, *handle, *geom_a, *geom_b
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSUnaryUnion_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      # Deprecated in GEOS 3.3.0. Use GEOSUnaryUnion_r instead.
      :GEOSUnionCascaded_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSPointOnSurface_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSGetCentroid_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSEnvelope_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSLineMerge_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSSimplify_r => [
        # *geom, *handle, *geom, tolerance
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSTopologyPreserveSimplify_r => [
        # *geom, *handle, *geom, tolerance
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSGeom_extractUniquePoints_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSSharedPaths_r => [
        # *geom, *handle, *geom_a, *geom_b
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSnap_r => [
        # *geom, *handle, *geom_a, *geom_b, tolerance
        :pointer, :pointer, :pointer, :pointer, :double
      ],

      :GEOSRelate_r => [
        # string, *handle, *geom_a, *geom_b
        :string, :pointer, :pointer, :pointer
      ],

      :GEOSRelatePatternMatch_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, pattern_a, pattern_b
        :char, :pointer, :string, :string
      ],

      :GEOSRelatePattern_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b, pattern
        :char, :pointer, :pointer, :pointer, :string
      ],

      :GEOSRelateBoundaryNodeRule_r => [
        # string, *handle, *geom_a, *geom_b, bnr
        :string, :pointer, :pointer, :pointer, :relate_boundary_node_rule
      ],

      :GEOSDisjoint_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSTouches_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSIntersects_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSCrosses_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSWithin_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSContains_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSOverlaps_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSCovers_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSCoveredBy_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSEquals_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSEqualsExact_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom_a, *geom_b
        :char, :pointer, :pointer, :pointer, :double
      ],

      :GEOSisEmpty_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSisValid_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSisValidReason_r => [
        # reason, *handle, *geom
        :string, :pointer, :pointer
      ],

      :GEOSisValidDetail_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom, flags, (string**) reasons, **geoms
        :char, :pointer, :pointer, :int, :pointer, :pointer
      ],

      :GEOSisSimple_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSisRing_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSHasZ_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSisClosed_r => [
        # (2 on exception, 1 on true, 2 on false), *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSArea_r => [
        # (0 on exception, 1 otherwise), *handle, *geom, (double *) area
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSLength_r => [
        # (0 on exception, 1 otherwise), *handle, *geom, (double *) length
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSDistance_r => [
        # (0 on exception, 1 otherwise), *handle, *geom_a, *geom_b, (double *) distance
        :int, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSHausdorffDistance_r => [
        # (0 on exception, 1 otherwise), *handle, *geom_a, *geom_b, (double *) distance
        :int, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSGetGeometryN_r => [
        # *geom, *handle, *geom, n
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGetNumInteriorRings_r => [
        # rings, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSNormalize_r => [
        # -1 on exception, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGetInteriorRingN_r => [
        # *geom, *handle, *geom, n
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGetExteriorRing_r => [
        # *geom, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetNumPoints_r => [
        # numpoints, *handle, *geom
        :int, :pointer, :pointer
      ],

      :GEOSGeomGetX_r => [
        # -1 on exception, *handle, *geom, *point
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetY_r => [
        # -1 on exception, *handle, *geom, *point
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetPointN_r => [
        # *point, *handle, *geom, n
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGeomGetStartPoint_r => [
        # *point, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetEndPoint_r => [
        # *point, *handle, *geom
        :pointer, :pointer, :pointer
      ],
      #### /Geometry functions ####

      #### STRtree functions ####
      :GEOSSTRtree_create_r => [
        # *tree, *handle, node_capacity
        :pointer, :pointer, :size_t
      ],

      :GEOSSTRtree_insert_r => [
        # void, *handle, *tree, *geom, *void
        :void, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSTRtree_query_r => [
        # void, *handle, *tree, *geom, void query_callback((void *) item, (void *) user_data), (void *) user_data
        :void, :pointer, :pointer, :pointer, callback([ :pointer, :pointer ], :void), :pointer
      ],

      :GEOSSTRtree_iterate_r => [
        # void, *handle, *tree, void query_callback((void *) item, (void *) user_data), (void *) user_data
        :void, :pointer, :pointer, callback([ :pointer, :pointer ], :void), :pointer
      ],

      :GEOSSTRtree_remove_r => [
        # bool, *handle, *tree, *geom, (void *) item
        :char, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSTRtree_destroy_r => [
        # void, *handle, *tree
        :void, :pointer, :pointer
      ],
      #### /STRtree functions ####

      #### PreparedGeometry functions ####
      :GEOSPrepare_r => [
        # *prepared, *handle, *geom
        :pointer, :pointer, :pointer
      ],

      :GEOSPreparedGeom_destroy_r => [
        # void, *handle, *geom
        :void, :pointer, :pointer
      ],

      :GEOSPreparedContains_r => [
        # (2 on exception, 1 on true, 0 on false), *handle, *prepared, *geom
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSPreparedContainsProperly_r => [
        # (2 on exception, 1 on true, 0 on false), *handle, *prepared, *geom
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSPreparedCovers_r => [
        # (2 on exception, 1 on true, 0 on false), *handle, *prepared, *geom
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSPreparedIntersects_r => [
        # (2 on exception, 1 on true, 0 on false), *handle, *prepared, *geom
        :char, :pointer, :pointer, :pointer
      ],
      #### /PreparedGeometry functions ####

      #### WktReader functions ####
      :GEOSWKTReader_create_r => [
        # *wktr, *handle
        :pointer, :pointer
      ],

      :GEOSWKTReader_read_r => [
        # *geom, *handle, *wktr, string
        :pointer, :pointer, :pointer, :string
      ],

      :GEOSWKTReader_destroy_r => [
        # void, *handle, *wktr
        :void, :pointer, :pointer
      ],
      #### /WktReader functions ###

      #### WktWriter functions ####
      :GEOSWKTWriter_create_r => [
        # *wktw, *handle
        :pointer, :pointer
      ],

      :GEOSWKTWriter_write_r => [
        # string, *handle, *wktw, *geom
        :string, :pointer, :pointer, :pointer
      ],

      :GEOSWKTWriter_destroy_r => [
        # void, *handle, *wktw
        :void, :pointer, :pointer
      ],

      :GEOSWKTWriter_setTrim_r => [
        # void, *handle, *wktw, bool
        :void, :pointer, :pointer, :char
      ],

      :GEOSWKTWriter_setRoundingPrecision_r => [
        # void, *handle, *wktw, precision
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKTWriter_setOutputDimension_r => [
        # void, *handle, *wktw, dimensions
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKTWriter_getOutputDimension_r => [
        # dimensions, *handle, *wktw
        :int, :pointer, :pointer
      ],

      :GEOSWKTWriter_setOld3D_r => [
        # void, *handle, *wktw, bool
        :void, :pointer, :pointer, :int
      ],
      #### /WktWriter functions ####

      #### WkbReader functions ####
      :GEOSWKBReader_create_r => [
        # *wkbr, *handle
        :pointer, :pointer
      ],

      :GEOSWKBReader_destroy_r => [
        # void, *handle, *wkbr
        :void, :pointer, :pointer
      ],

      :GEOSWKBReader_read_r => [
        # *geom, *handle, *wkbr, (unsigned char *) string, size_t
        :pointer, :pointer, :pointer, :pointer, :size_t
      ],

      :GEOSWKBReader_readHEX_r => [
        # *geom, *handle, *wkbr, string, size_t
        :pointer, :pointer, :pointer, :string, :size_t
      ],
      #### /WkbReader functions ####

      #### WkbWriter functions ####
      :GEOSWKBWriter_create_r => [
        # *wkbw, *handle
        :pointer, :pointer
      ],

      :GEOSWKBWriter_destroy_r => [
        # void, *handle, *wkbw
        :void, :pointer, :pointer
      ],

      :GEOSWKBWriter_write_r => [
        # (unsigned char *) string, *handle, *wkbw, *geom, *size_t
        :pointer, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSWKBWriter_writeHEX_r => [
        # (unsigned char *) string, *handle, *wkbw, *geom, *size_t
        :pointer, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSWKBWriter_setOutputDimension_r => [
        # void, *handle, *wkbw, dimensions
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKBWriter_getOutputDimension_r => [
        # dimensions, *handle, *wkbw
        :int, :pointer, :pointer
      ],

      :GEOSWKBWriter_getByteOrder_r => [
        # byte_order, *handle, *wkbw
        :byte_order, :pointer, :pointer
      ],

      :GEOSWKBWriter_setByteOrder_r => [
        # void, *handle, *wkbw, byte_order
        :void, :pointer, :pointer, :byte_order
      ],

      :GEOSWKBWriter_getIncludeSRID_r => [
        # bool, *handle, *geom
        :char, :pointer, :pointer
      ],

      :GEOSWKBWriter_setIncludeSRID_r => [
        # void, *handle, *geom, bool
        :void, :pointer, :pointer, :char
      ],
      #### /WkbWriter functions ####


      #### Linearref functions ####
      :GEOSProject_r => [
        # distance, *handle, *geom_a, *geom_b
        :double, :pointer, :pointer, :pointer
      ],

      :GEOSProjectNormalized_r => [
        # distance, *handle, *geom_a, *geom_b
        :double, :pointer, :pointer, :pointer
      ],

      :GEOSInterpolate_r => [
        # *geom, *handle, *geom, distance
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSInterpolateNormalized_r => [
        # *geom, *handle, *geom, distance
        :pointer, :pointer, :pointer, :double
      ],
      #### /Linearref functions ####

      #### Algorithms ####
      # -1 if reaching P takes a counter-clockwise (left) turn
      # 1 if reaching P takes a clockwise (right) turn
      # 0 if P is collinear with A-B
      :GEOSOrientationIndex_r => [
        # int, *handle, Ax, Ay, Bx, By, Px, Py
        :int, :pointer, :double, :double, :double, :double, :double, :double
      ]
      #### /Algorithms ####
    }

    FFI_LAYOUT.each do |fun, ary|
      ret = ary.shift
      begin
        self.class_eval do
          attach_function(fun, ary, ret)
        end
      rescue FFI::NotFoundError
        # that's okay
      end
    end
  end

  class Handle
    attr_reader :ptr

    def initialize
      @ptr = FFIGeos.initGEOS_r(
        @notice_handler = self.method(:notice_handler),
        @error_handler = self.method(:error_handler)
      )

      Kernel.at_exit {
        FFIGeos.finishGEOS_r(@ptr)
      }
    end

    def notice_handler(*args)
      # no-op, just to appease initGEOS.
    end

    def error_handler(*args)
      raise RuntimeError.new(args[0] % args[1])
    end
  end

  class << self
    def version
      @version ||= FFIGeos.GEOSversion
    end

    def jts_port
      @jts_port ||= FFIGeos.GEOSjtsport
    end

    def current_handle
      Thread.current[:ffi_geos_handle] ||= Geos::Handle.new
      Thread.current[:ffi_geos_handle].ptr
    end

    %w{
      create_point
      create_line_string
      create_linear_ring
      create_polygon
      create_multi_point
      create_multi_line_string
      create_multi_polygon
      create_geometry_collection

      create_empty_point
      create_empty_line_string
      create_empty_polygon
      create_empty_multi_point
      create_empty_multi_line_string
      create_empty_multi_polygon
      create_empty_geometry_collection
    }.each do |m|
      self.class_eval <<-EOF
        def #{m}(*args)
          Geos::Utils.#{m}(*args)
        end
      EOF
    end
  end

  module GeomTypes
    GEOS_POINT = 0
    GEOS_LINESTRING = 1
    GEOS_LINEARRING = 2
    GEOS_POLYGON = 3
    GEOS_MULTIPOINT = 4
    GEOS_MULTILINESTRING = 5
    GEOS_MULTIPOLYGON = 6
    GEOS_GEOMETRYCOLLECTION = 7
  end

  module VersionConstants
    VERSION = File.read(File.join(GEOS_BASE, %w{ .. VERSION })).strip
    GEOS_JTS_PORT = Geos.jts_port
    GEOS_VERSION,
      GEOS_VERSION_MAJOR, GEOS_VERSION_MINOR, GEOS_VERISON_PATCH,
      GEOS_CAPI_VERSION,
      GEOS_CAPI_VERSION_MAJOR, GEOS_CAPI_VERSION_MINOR, GEOS_CAPI_VERSION_PATCH =
        if versions = Geos.version.scan(/^((\d+)\.(\d+)\.(\d+))-CAPI-((\d+)\.(\d+)\.(\d+))$/)
          versions = versions[0]
          [
            versions[0],
            versions[1].to_i,
            versions[2].to_i,
            versions[3].to_i,
            versions[4],
            versions[5].to_i,
            versions[6].to_i,
            versions[7].to_i
          ]
        else
          []
        end
    GEOS_CAPI_FIRST_INTERFACE = GEOS_CAPI_VERSION_MAJOR.to_i
    GEOS_CAPI_LAST_INTERFACE = GEOS_CAPI_VERSION_MAJOR.to_i + GEOS_CAPI_VERSION_MINOR.to_i
  end

  module Constants
    BUFFER_PARAM_DEFAULTS = {
      :quad_segs => 8,
      :endcap => :round,
      :join => :round,
      :mitre_limit => 5.0
    }.freeze
  end

  include GeomTypes
  include VersionConstants
end
