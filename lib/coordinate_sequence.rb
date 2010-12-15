
module Geos

  # A CoordinateSequence is a list of coordinates in a Geometry.
  class CoordinateSequence
    include Enumerable

    attr_reader :ptr

    # :call-seq:
    #   new(ptr, auto_free = true)
    #   new(size, dims = 0)
    #
    # The ptr version of the initializer is for internal use.
    def initialize(*args)
      ptr, auto_free = if args.first.is_a?(FFI::Pointer)
        [ args.first, args[1] ]
      else
        size, dims = if !args.length.between?(1, 2)
          raise ArgumentError.new("wrong number of arguments (#{args.length} for 1-2)")
        else
          [ args[0], args[1] || 0]
        end

        [ FFIGeos.GEOSCoordSeq_create_r(Geos.current_handle, size, dims), true ]
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        auto_free ? self.class.method(:release) : self.class.method(:no_release)
      )
    end

    def self.no_release(ptr) #:nodoc:
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSCoordSeq_destroy_r(Geos.current_handle, ptr)
    end

    def clone
      self.class.new(FFIGeos.GEOSCoordSeq_clone_r(Geos.current_handle, self.ptr))
    end

    # Yields coordinates as [ x, y, z ]. The z coordinate may be omitted for
    # 2-dimensional CoordinateSequences.
    def each
      self.length.times do |n|
        yield [
          self.get_x(n),
          (self.dimensions >= 2 ? self.get_y(n) : nil),
          (self.dimensions >= 3 ? self.get_z(n) : nil)
        ].compact
      end
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
    alias :size :length

    def dimensions
      @dimensions ||= FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSCoordSeq_getDimensions_r(Geos.current_handle, self.ptr, ret)
      }.read_int
    end

    protected

    def check_bounds(idx) #:nodoc:
      if idx < 0 || idx >= self.length
        raise RuntimeError.new("Index out of bounds")
      end
    end
  end
end
