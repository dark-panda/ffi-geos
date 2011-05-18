
module Geos
  class WktReader
    include Geos::Tools

    attr_reader :ptr

    def initialize(*args)
      ptr = if args.first.is_a?(FFI::Pointer)
        args.first
      else
        FFIGeos.GEOSWKTReader_create_r(Geos.current_handle, *args)
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )
    end

    def read(wkt)
      cast_geometry_ptr(FFIGeos.GEOSWKTReader_read_r(Geos.current_handle, self.ptr, wkt))
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKTReader_destroy_r(Geos.current_handle, ptr)
    end
  end
end
