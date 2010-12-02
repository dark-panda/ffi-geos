
module Geos
  class CoordinateSequence
    attr_reader :ptr

    def initialize(*args)
      ptr = if args.first.is_a?(FFI::Pointer)
        args.first
      else
        FFIGeos.GEOSCoordSeq_create_r(Geos.current_handle, *args)
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )
    end

    def self.release(ptr)
      FFIGeos.GEOSCoordSeq_destroy_r(Geos.current_handle, ptr)
    end

    def clone
      self.class.new(FFIGeos.GEOSCoordSeq_clone_r(Geos.current_handle, self.ptr))
    end

    def set_x(idx, val)
      self.check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setX_r(Geos.current_handle, self.ptr, idx, val)
    end

    def set_y(idx, val)
      self.check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setY_r(Geos.current_handle, self.ptr, idx, val)
    end

    def set_z(idx, val)
      self.check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setZ_r(Geos.current_handle, self.ptr, idx, val)
    end

    def set_ordinate(idx, dim, val)
      self.check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setOrdinate_r(Geos.current_handle, self.ptr, idx, dim, val)
    end

    def get_x(idx)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getX_r(Geos.current_handle, self.ptr, idx, ret)
      }.get_double(0)
    end

    def get_y(idx)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getY_r(Geos.current_handle, self.ptr, idx, ret)
      }.get_double(0)
    end

    def get_z(idx)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getZ_r(Geos.current_handle, self.ptr, idx, ret)
      }.get_double(0)
    end

    def get_ordinate(idx, dim)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getOrdinate_r(Geos.current_handle, self.ptr, idx, dim, ret)
      }.get_double(0)
    end

    def length
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getSize_r(Geos.current_handle, self.ptr, ret)
      }.read_int
    end

    def dimensions
      @dimensions ||= FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getDimensions_r(Geos.current_handle, self.ptr, ret)
      }.read_int
    end

    protected

    def check_bounds(idx)
      if idx < 0 || idx >= self.length
        raise RuntimeError.new("Index out of bounds")
      end
    end
  end
end
