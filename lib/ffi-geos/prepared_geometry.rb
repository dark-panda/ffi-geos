# encoding: UTF-8

module Geos
  class PreparedGeometry
    include Geos::Tools

    attr_reader :ptr, :geometry

    undef :clone, :dup

    def initialize(geom, auto_free = true)
      check_geometry(geom)

      @ptr = FFI::AutoPointer.new(
        FFIGeos.GEOSPrepare_r(Geos.current_handle, geom.ptr),
        self.class.method(:release)
      )
      @geometry = geom

      @ptr.autorelease = auto_free
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSPreparedGeom_destroy_r(Geos.current_handle, ptr)
    end

    def contains?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedContains_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def contains_properly?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedContainsProperly_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def covered_by?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedCoveredBy_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def covers?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedCovers_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def crosses?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedCrosses_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def disjoint?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedDisjoint_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def intersects?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedIntersects_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def overlaps?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedOverlaps_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def touches?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedTouches_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def within?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedWithin_r(Geos.current_handle, self.ptr, geom.ptr))
    end
  end
end
