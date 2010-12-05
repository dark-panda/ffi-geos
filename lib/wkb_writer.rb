
module Geos
  class WkbWriter
    include Geos::Tools

    attr_reader :ptr

    def initialize(*args)
      ptr = if args.first.is_a?(FFI::Pointer)
        args.first
      else
        FFIGeos.GEOSWKBWriter_create_r(Geos.current_handle, *args)
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )
    end

    def self.release(ptr)
      FFIGeos.GEOSWKBWriter_destroy_r(Geos.current_handle, ptr)
    end

    def write(geom)
      size_t = FFI::MemoryPointer.new(:pointer)
      FFIGeos.GEOSWKBWriter_write_r(Geos.current_handle, self.ptr, geom.ptr, size_t).get_string(0, size_t.read_int)
    end

    def write_hex(geom)
      size_t = FFI::MemoryPointer.new(:pointer)
      FFIGeos.GEOSWKBWriter_writeHEX_r(Geos.current_handle, self.ptr, geom.ptr, size_t).get_string(0, size_t.read_int)
    end

    def output_dimensions=(dim)
      if dim < 2 || dim > 3
        raise RuntimeError.new("Output dimensions must be either 2 or 3")
      end
      FFIGeos.GEOSWKBWriter_setOutputDimension_r(Geos.current_handle, self.ptr, dim)
    end

    def output_dimensions
      FFIGeos.GEOSWKBWriter_getOutputDimension_r(Geos.current_handle, self.ptr)
    end

    def old_3d=(val)
      FFIGeos.GEOSWKBWriter_setOld3D_r(Geos.current_handle, self.ptr,
        val ? 1 : 0
      )
    end

    def include_srid
      Geos::Util.bool_result(FFIGeos.GEOSWKBWriter_getIncludeSRID_r(Geos.current_handle, self.ptr))
    end

    def include_srid=(val)
      FFIGeos.GEOSWKBWriter_setIncludeSRID_r(Geos.current_handle, self.ptr,
        val ? 1 : 0
      )
    end

    def byte_order
      Geos::Util.bool_result(FFIGeos.GEOSWKBWriter_getByteOrder_r(Geos.current_handle, self.ptr))
    end

    def byte_order=(val)
      val = if !val.is_a?(Fixnum)
        raise TypeError.new("Expected Fixnum")
      elsif [ Geos::ByteOrders::XDR, Geos::ByteOrders::NDR ].include?(val)
        val
      else
        Geos::ByteOrders::NDR
      end

      FFIGeos.GEOSWKBWriter_setByteOrder_r(Geos.current_handle, self.ptr, val)
    end
  end
end
