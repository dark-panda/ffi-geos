
module Geos

  # A CoordinateSequence is a list of coordinates in a Geometry.
  class CoordinateSequence
    class ParseError < ArgumentError
    end

    include Enumerable

    attr_reader :ptr

    # :call-seq:
    #   new(ptr, auto_free = true)
    #   new(size = 0, dims = 0)
    #   new(points)
    #
    # The ptr version of the initializer is for internal use.
    #
    # new(points) will try to glean the size and dimensions of your
    # CoordinateSequence from an Array of points. The Array should contain
    # uniform-sized Arrays which represent the [ x, y, z ] values of your
    # coordinates.
    def initialize(*args)
      points = nil # forward declaration we can use later

      ptr, auto_free = if args.first.is_a?(FFI::Pointer)
        [ args.first, args[1] ]
      else
        size, dims = if args.first.is_a?(Array)
          points = if args.first.first.is_a?(Array)
            args.first
          else
            args
          end
          lengths = points.collect(&:length).uniq

          if lengths.empty?
            [ 0, 0 ]
          elsif lengths.length != 1
            raise ParseError.new("Different sized points found in Array")
          elsif !lengths.first.between?(1, 3)
            raise ParseError.new("Expected points to contain 1-3 elements")
          else
            [ points.length, points.first.length ]
          end
        else
          if !args.length.between?(0, 2)
            raise ArgumentError.new("wrong number of arguments (#{args.length} for 0-2)")
          else
            [ args[0] || 0, args[1] || 0 ]
          end
        end

        [ FFIGeos.GEOSCoordSeq_create_r(Geos.current_handle, size, dims), true ]
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        auto_free ? self.class.method(:release) : self.class.method(:no_release)
      )

      if !auto_free
        @ptr.autorelease = false
      end

      if points
        points.each_with_index do |point, idx|
          point.each_with_index do |val, dim|
            self.set_ordinate(idx, dim, val)
          end
        end
      end
    end

    def initialize_copy(source)
      @ptr = FFI::AutoPointer.new(
        FFIGeos.GEOSCoordSeq_clone_r(Geos.current_handle, source.ptr),
        self.class.method(:release)
      )
    end

    def self.no_release(ptr) #:nodoc:
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSCoordSeq_destroy_r(Geos.current_handle, ptr)
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
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSCoordSeq_getX_r(Geos.current_handle, self.ptr, idx, ret)
      }.read_double
    end

    def get_y(idx)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSCoordSeq_getY_r(Geos.current_handle, self.ptr, idx, ret)
      }.read_double
    end

    def get_z(idx)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSCoordSeq_getZ_r(Geos.current_handle, self.ptr, idx, ret)
      }.read_double
    end

    def get_ordinate(idx, dim)
      self.check_bounds(idx)
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSCoordSeq_getOrdinate_r(Geos.current_handle, self.ptr, idx, dim, ret)
      }.read_double
    end

    def length
      FFI::MemoryPointer.new(:int).tap { |ret|
        FFIGeos.GEOSCoordSeq_getSize_r(Geos.current_handle, self.ptr, ret)
      }.read_int
    end
    alias :size :length

    def empty?
      self.length == 0
    end

    def dimensions
      @dimensions ||= FFI::MemoryPointer.new(:int).tap { |ret|
        FFIGeos.GEOSCoordSeq_getDimensions_r(Geos.current_handle, self.ptr, ret)
      }.read_int
    end

    def to_point
      Geos.create_point(self)
    end

    def to_linear_ring
      Geos.create_linear_ring(self)
    end

    def to_line_string
      Geos.create_line_string(self)
    end

    def to_polygon
      Geos.create_polygon(self)
    end

    def to_s
      self.entries.collect { |entry|
        entry.join(' ')
      }.join(', ')
    end

    protected

    def check_bounds(idx) #:nodoc:
      if idx < 0 || idx >= self.length
        raise RuntimeError.new("Index out of bounds")
      end
    end
  end
end
