
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
  autoload :Tools,
    File.join(GEOS_BASE, 'tools')
  autoload :Utils,
    File.join(GEOS_BASE, 'utils')

  module FFIGeos
    def self.geos_library_name
      paths = if ENV['GEOS_LIBRARY_PATH']
        [ ENV['GEOS_LIBRARY_PATH'] ]
      else
        [ '/usr/lib', '/usr/local/lib', '/opt/local/lib' ]
      end

      libs = case Config::CONFIG['arch']
        when /darwin/
          %w{ libgeos_c.dylib  libgeos.dylib }
        else
          %w{ libgeos.so libgeos_c.so }
      end

      libs.collect { |lib|
        paths.detect { |path|
          File.exists?("#{path}/#{lib}")
        }.to_s + "/#{lib}"
      }
    end

    extend ::FFI::Library

    ffi_lib(*geos_library_name)

    FFI_LAYOUT = {
      #### Utility functions ####
      :initGEOS_r => [
        :pointer,
        callback([ :string, :varargs ], :void),
        callback([ :string, :varargs ], :void)
      ],

      :finishGEOS_r => [
        :void, :pointer
      ],

      :GEOSversion => [
        :string
      ],

      :GEOSPolygonize_r => [
        :pointer, :pointer, :pointer, :uint
      ],

      :GEOSPolygonizer_getCutEdges_r => [
        :pointer, :pointer, :pointer, :uint
      ],

      :GEOSPolygonize_full_r => [
        :pointer, :pointer, :pointer, :pointer, :pointer, :pointer
      ],
      #### /Utility functions ####

      #### CoordinateSequence functions ####
      :GEOSCoordSeq_create_r => [
        :pointer, :pointer, :uint, :uint
      ],

      :GEOSCoordSeq_destroy_r => [
        :void, :pointer, :pointer
      ],

      :GEOSCoordSeq_clone_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSCoordSeq_setX_r => [
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setY_r => [
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setZ_r => [
        :int, :pointer, :pointer, :uint, :double
      ],

      :GEOSCoordSeq_setOrdinate_r => [
        :int, :pointer, :pointer, :uint, :uint, :double
      ],

      :GEOSCoordSeq_getX_r => [
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getY_r => [
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getZ_r => [
        :int, :pointer, :pointer, :uint, :pointer
      ],

      :GEOSCoordSeq_getOrdinate_r => [
        :int, :pointer, :pointer, :uint, :uint, :pointer
      ],

      :GEOSCoordSeq_getSize_r => [
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSNormalize_r => [
        :int, :pointer, :pointer
      ],

      :GEOSCoordSeq_getDimensions_r => [
        :int, :pointer, :pointer, :pointer
      ],
      #### /CoordinateSequence functions ####

      #### Geometry functions ####
      :GEOSGeom_destroy_r => [
        :void, :pointer, :pointer
      ],

      :GEOSGeom_clone_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomTypeId_r => [
        :int, :pointer, :pointer
      ],

      :GEOSGeomType_r => [
        :string, :pointer, :pointer
      ],

      :GEOSGetSRID_r => [
        :int, :pointer, :pointer
      ],

      :GEOSSetSRID_r => [
        :void, :pointer, :pointer, :int
      ],

      :GEOSGeom_getDimensions_r => [
        :int, :pointer, :pointer
      ],

      :GEOSGetNumGeometries_r => [
        :int, :pointer, :pointer
      ],

      :GEOSGetNumCoordinates_r => [
        :int, :pointer, :pointer
      ],

      :GEOSIntersection_r => [
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSBuffer_r => [
        :pointer, :pointer, :pointer, :double, :int
      ],

      :GEOSConvexHull_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSDifference_r => [
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSymDifference_r => [
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSBoundary_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSUnion_r => [
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSUnionCascaded_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSPointOnSurface_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSGetCentroid_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSEnvelope_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSRelate_r => [
        :string, :pointer, :pointer, :pointer
      ],

      :GEOSLineMerge_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSSimplify_r => [
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSTopologyPreserveSimplify_r => [
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSGeom_extractUniquePoints_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSSharedPaths_r => [
        :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSSnap_r => [
        :pointer, :pointer, :pointer, :pointer, :double
      ],

      :GEOSRelatePattern_r => [
        :char, :pointer, :pointer, :pointer, :string
      ],

      :GEOSDisjoint_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSTouches_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSIntersects_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSCrosses_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSWithin_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSContains_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSOverlaps_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSEquals_r => [
        :char, :pointer, :pointer, :pointer
      ],

      :GEOSEqualsExact_r => [
        :char, :pointer, :pointer, :pointer, :double
      ],

      :GEOSisEmpty_r => [
        :char, :pointer, :pointer
      ],

      :GEOSisValid_r => [
        :char, :pointer, :pointer
      ],

      :GEOSisValidReason_r => [
        :string, :pointer, :pointer
      ],

      :GEOSisValidDetail_r => [
        :char, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSisSimple_r => [
        :char, :pointer, :pointer
      ],

      :GEOSisRing_r => [
        :char, :pointer, :pointer
      ],

      :GEOSHasZ_r => [
        :char, :pointer, :pointer
      ],

      :GEOSisClosed_r => [
        :char, :pointer, :pointer
      ],

      :GEOSArea_r => [
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSLength_r => [
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSDistance_r => [
        :int, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSHausdorffDistance_r => [
        :int, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSGetGeometryN_r => [
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGetNumInteriorRings_r => [
        :int, :pointer, :pointer
      ],

      :GEOSGetInteriorRingN_r => [
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGetExteriorRing_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetNumPoints_r => [
        :int, :pointer, :pointer
      ],

      :GEOSGeomGetX_r => [
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetY_r => [
        :int, :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetPointN_r => [
        :pointer, :pointer, :pointer, :int
      ],

      :GEOSGeomGetStartPoint_r => [
        :pointer, :pointer, :pointer
      ],

      :GEOSGeomGetEndPoint_r => [
        :pointer, :pointer, :pointer
      ],

      #### /Geometry functions ####

      #### WktReader functions ####
      :GEOSWKTReader_create_r => [
        :pointer, :pointer
      ],

      :GEOSWKTReader_read_r => [
        :pointer, :pointer, :pointer, :string
      ],

      :GEOSWKTReader_destroy_r => [
        :void, :pointer, :pointer
      ],
      #### /WktReader functions ###

      #### WktWriter functions ####
      :GEOSWKTWriter_create_r => [
        :pointer, :pointer
      ],

      :GEOSWKTWriter_write_r => [
        :string, :pointer, :pointer, :pointer
      ],

      :GEOSWKTWriter_destroy_r => [
        :void, :pointer, :pointer
      ],

      :GEOSWKTWriter_setTrim_r => [
        :void, :pointer, :pointer, :char
      ],

      :GEOSWKTWriter_setRoundingPrecision_r => [
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKTWriter_setOutputDimension_r => [
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKTWriter_getOutputDimension_r => [
        :int, :pointer, :pointer
      ],

      :GEOSWKTWriter_setOld3D_r => [
        :void, :pointer, :pointer, :int
      ],
      #### /WktWriter functions ####

      #### WkbReader functions ####
      :GEOSWKBReader_create_r => [
        :pointer, :pointer
      ],

      :GEOSWKBReader_destroy_r => [
        :void, :pointer, :pointer
      ],

      :GEOSWKBReader_read_r => [
        :pointer, :pointer, :pointer, :string, :size_t
      ],

      :GEOSWKBReader_readHEX_r => [
        :pointer, :pointer, :pointer, :string, :size_t
      ],
      #### /WkbReader functions ####

      #### WkbWriter functions ####
      :GEOSWKBWriter_create_r => [
        :pointer, :pointer
      ],

      :GEOSWKBWriter_destroy_r => [
        :void, :pointer, :pointer
      ],

      :GEOSWKBWriter_write_r => [
        :string, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSWKBWriter_writeHEX_r => [
        :string, :pointer, :pointer, :pointer, :pointer
      ],

      :GEOSWKBWriter_setOutputDimension_r => [
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKBWriter_getOutputDimension_r => [
        :int, :pointer, :pointer
      ],

      :GEOSWKBWriter_getByteOrder_r => [
        :int, :pointer, :pointer
      ],

      :GEOSWKBWriter_setByteOrder_r => [
        :void, :pointer, :pointer, :int
      ],

      :GEOSWKBWriter_getIncludeSRID_r => [
        :char, :pointer, :pointer
      ],

      :GEOSWKBWriter_setIncludeSRID_r => [
        :void, :pointer, :pointer, :char
      ],
      #### /WkbWriter functions ####


      #### Linearref functions ####
      :GEOSProject_r => [
        :double, :pointer, :pointer, :pointer
      ],

      :GEOSProjectNormalized_r => [
        :double, :pointer, :pointer, :pointer
      ],

      :GEOSInterpolate_r => [
        :pointer, :pointer, :pointer, :double
      ],

      :GEOSInterpolateNormalized_r => [
        :pointer, :pointer, :pointer, :double
      ],
      #### /Linearref functions ####

      #### Algorithms ####
      :GEOSOrientationIndex_r => [
        :int, :pointer, :double, :double, :double, :double, :double, :double
      ]
      #### /Algorithms ####
    }

    FFI_LAYOUT.each do |fun, ary|
      ret = ary.shift
      self.class_eval do
        attach_function(fun, ary, ret)
      end
    end
  end

  class << self
    def version
      @version ||= FFIGeos.GEOSversion
    end

    def current_handle
      Thread.current[:ffi_geos_handle] ||= FFIGeos.initGEOS_r(
        self.method(:notice_handler),
        self.method(:error_handler)
      )
    end

    def notice_handler(*args)
      # no-op, just to appease initGEOS.
    end

    def error_handler(*args)
      raise RuntimeError
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

  module DimensionTypes
    DONTCARE = -3
    NON_EMPTY = -2
    EMPTY = -1
    POINT = 0
    CURVE = 1
    SURFACE = 2
  end

  module ByteOrders
    XDR = 0 # Big Endian
    NDR = 1 # Little Endian
  end

  module VersionConstants
    #GEOS_JTS_PORT = Geos.jts_port
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

  include GeomTypes
  include VersionConstants

  #Kernel.at_exit {
  #  FFIGeos.finishGEOS
  #}
end
