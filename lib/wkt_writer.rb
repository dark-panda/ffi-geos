
module Geos
  class WktWriter
    attr_reader :ptr

    def initialize(*args)
      ptr = if args.first.is_a?(FFI::Pointer)
        args.first
      else
        FFIGeos.GEOSWKTWriter_create_r(Geos.current_handle, *args)
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKTWriter_destroy_r(Geos.current_handle, ptr)
    end

    def write(geom)
      FFIGeos.GEOSWKTWriter_write_r(Geos.current_handle, self.ptr, geom.ptr)
    end

    def trim=(val)
      FFIGeos.GEOSWKTWriter_setTrim_r(Geos.current_handle, self.ptr,
        val ? 1 : 0
      )
    end

    def rounding_precision=(r)
      FFIGeos.GEOSWKTWriter_setRoundingPrecision_r(Geos.current_handle, self.ptr, r)
    end

    def old_3d=(val)
      FFIGeos.GEOSWKTWriter_setOld3D_r(Geos.current_handle, self.ptr,
        val ? 1 : 0
      )
    end

    def output_dimensions=(dim)
      if dim < 2 || dim > 3
        raise RuntimeError.new("Output dimensions must be either 2 or 3")
      end
      FFIGeos.GEOSWKTWriter_setOutputDimension_r(Geos.current_handle, self.ptr, dim)
    end

    def output_dimensions
      FFIGeos.GEOSWKTWriter_getOutputDimension_r(Geos.current_handle, self.ptr)
    end
  end
end
