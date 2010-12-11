
module Geos
  class PreparedGeometry
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

    def covers?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedCovers_r(Geos.current_handle, self.ptr, geom.ptr))
    end

    def intersects?(geom)
      check_geometry(geom)
      bool_result(FFIGeos.GEOSPreparedIntersects_r(Geos.current_handle, self.ptr, geom.ptr))
    end
  end
end
