# frozen_string_literal: true

module Geos
  # A CoordinateSequence is a list of coordinates in a Geometry.
  class CoordinateSequence
    class ParseError < Geos::ParseError
    end

    class CoordinateAccessor
      attr_accessor :parent, :dimension

      include Enumerable

      def initialize(parent, dimension)
        @parent = parent
        @dimension = dimension
      end

      def [](idx)
        parent.get_ordinate(idx, dimension)
      end

      def []=(idx, value)
        parent.set_ordinate(idx, dimension, value)
      end

      def each
        if block_given?
          parent.length.times do |n|
            yield parent.get_ordinate(n, dimension)
          end
          self
        else
          parent.length.times.collect { |n|
            parent.get_ordinate(n, dimension)
          }.to_enum
        end
      end
    end

    include Enumerable

    attr_reader :ptr, :x, :y, :z

    # :call-seq:
    #   new(ptr, auto_free = true, parent = nil)
    #   new(size = 0, dimensions = 0)
    #   new(options)
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

      ptr, auto_free, parent = if args.first.is_a?(FFI::Pointer)
        args.first(3)
      else
        size, dimensions = if args.first.is_a?(Array)
          points = if args.first.first.is_a?(Array)
            args.first
          else
            args
          end
          lengths = points.collect(&:length).uniq

          if lengths.empty?
            [ 0, 0 ]
          elsif lengths.length != 1
            raise ParseError, 'Different sized points found in Array'
          elsif !lengths.first.between?(1, 3)
            raise ParseError, 'Expected points to contain 1-3 elements'
          else
            [ points.length, points.first.length ]
          end
        elsif args.first.is_a?(Hash)
          args.first.values_at(:size, :dimensions)
        else
          if !args.length.between?(0, 2)
            raise ArgumentError, "wrong number of arguments (#{args.length} for 0-2)"
          else
            [ args[0], args[1] ]
          end
        end

        size ||= 0
        dimensions ||= 0

        [ FFIGeos.GEOSCoordSeq_create_r(Geos.current_handle_pointer, size, dimensions), true ]
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      @ptr.autorelease = auto_free
      @parent = parent if parent

      @x = CoordinateAccessor.new(self, 0)
      @y = CoordinateAccessor.new(self, 1)
      @z = CoordinateAccessor.new(self, 2)

      return unless points

      points.each_with_index do |point, idx|
        point.each_with_index do |val, dim|
          set_ordinate(idx, dim, val)
        end
      end
    end

    def initialize_copy(source)
      @ptr = FFI::AutoPointer.new(
        FFIGeos.GEOSCoordSeq_clone_r(Geos.current_handle_pointer, source.ptr),
        self.class.method(:release)
      )

      @x = CoordinateAccessor.new(self, 0)
      @y = CoordinateAccessor.new(self, 1)
      @z = CoordinateAccessor.new(self, 2)
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSCoordSeq_destroy_r(Geos.current_handle_pointer, ptr)
    end

    # Yields coordinates as [ x, y, z ]. The z coordinate may be omitted for
    # 2-dimensional CoordinateSequences.
    def each
      if block_given?
        length.times do |n|
          yield build_coordinate(n)
        end
        self
      else
        length.times.collect { |n|
          build_coordinate(n)
        }.to_enum
      end
    end

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        i = args.first
        ary = [ get_x(i), get_y(i) ]
        ary << get_z(i) if has_z?
        ary
      else
        to_a[*args]
      end
    end
    alias slice []

    def has_z?
      dimensions == 3
    end

    # Sets the x value of a coordinate. Can also be set via #x[]=.
    def set_x(idx, val)
      check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setX_r(Geos.current_handle_pointer, ptr, idx, val.to_f)
    end

    # Sets the y value of a coordinate. Can also be set via #y[]=.
    def set_y(idx, val)
      check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setY_r(Geos.current_handle_pointer, ptr, idx, val.to_f)
    end

    # Sets the z value of a coordinate. Can also be set via #z[]=.
    def set_z(idx, val)
      check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setZ_r(Geos.current_handle_pointer, ptr, idx, val.to_f)
    end

    def set_ordinate(idx, dim, val)
      check_bounds(idx)
      FFIGeos.GEOSCoordSeq_setOrdinate_r(Geos.current_handle_pointer, ptr, idx, dim, val.to_f)
    end

    # Gets the x value of a coordinate. Can also be retrieved via #x[].
    def get_x(idx)
      check_bounds(idx)
      double_ptr = FFI::MemoryPointer.new(:double)
      FFIGeos.GEOSCoordSeq_getX_r(Geos.current_handle_pointer, ptr, idx, double_ptr)
      double_ptr.read_double
    end

    # Gets the y value of a coordinate. Can also be retrieved via #y[].
    def get_y(idx)
      check_bounds(idx)
      double_ptr = FFI::MemoryPointer.new(:double)
      FFIGeos.GEOSCoordSeq_getY_r(Geos.current_handle_pointer, ptr, idx, double_ptr)
      double_ptr.read_double
    end

    # Gets the z value of a coordinate. Can also be retrieved via #z[].
    def get_z(idx)
      check_bounds(idx)
      double_ptr = FFI::MemoryPointer.new(:double)
      FFIGeos.GEOSCoordSeq_getZ_r(Geos.current_handle_pointer, ptr, idx, double_ptr)
      double_ptr.read_double
    end

    def get_ordinate(idx, dim)
      check_bounds(idx)
      double_ptr = FFI::MemoryPointer.new(:double)
      FFIGeos.GEOSCoordSeq_getOrdinate_r(Geos.current_handle_pointer, ptr, idx, dim, double_ptr)
      double_ptr.read_double
    end

    def length
      int_ptr = FFI::MemoryPointer.new(:int)
      FFIGeos.GEOSCoordSeq_getSize_r(Geos.current_handle_pointer, ptr, int_ptr)
      int_ptr.read_int
    end
    alias size length

    def empty?
      length.zero?
    end

    def dimensions
      if defined?(@dimensions)
        @dimensions
      else
        int_ptr = FFI::MemoryPointer.new(:int)
        FFIGeos.GEOSCoordSeq_getDimensions_r(Geos.current_handle_pointer, ptr, int_ptr)
        @dimensions = int_ptr.read_int
      end
    end

    def to_point(options = {})
      Geos.create_point(self, srid: options[:srid])
    end

    def to_linear_ring(options = {})
      Geos.create_linear_ring(self, srid: options[:srid])
    end

    def to_line_string(options = {})
      Geos.create_line_string(self, srid: options[:srid])
    end

    def to_polygon(options = {})
      Geos.create_polygon(self, srid: options[:srid])
    end

    def to_s
      entries.collect { |entry|
        entry.join(' ')
      }.join(', ')
    end

    %w{ x y z }.each do |m|
      class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{m}_max
          ret = nil
          self.length.times do |i|
            value = self.get_#{m}(i)
            ret = value if !ret || value >= ret
          end
          ret
        end

        def #{m}_min
          ret = nil
          self.length.times do |i|
            value = self.get_#{m}(i)
            ret = value if !ret || value <= ret
          end
          ret
        end
      EOF
    end

    def snap_to_grid!(*args)
      grid = {
        :offset_x => 0, # 1
        :offset_y => 0, # 2
        :offset_z => 0, # -
        :size_x => 0, # 3
        :size_y => 0, # 4
        :size_z => 0 # -
      }

      if args.length == 1 && args[0].is_a?(Numeric)
        grid[:size_x] = grid[:size_y] = grid[:size_z] = args[0]
      elsif args[0].is_a?(Hash)
        grid.merge!(args[0])
      end

      if grid[:size]
        grid[:size_x] = grid[:size_y] = grid[:size_z] = grid[:size]
      end

      if grid[:offset]
        case grid[:offset]
          when Geos::Geometry
            point = grid[:offset].centroid

            grid[:offset_x] = point.x
            grid[:offset_y] = point.y
            grid[:offset_z] = point.z
          when Array
            grid[:offset_x], grid[:offset_y], grid[:offset_z] = grid[:offset]
          else
            raise ArgumentError.new("Expected :offset option to be a Geos::Point")
        end
      end

      self.length.times do |i|
        if grid[:size_x] != 0
          self.x[i] = ((self.x[i] - grid[:offset_x]) / grid[:size_x]).round * grid[:size_x] + grid[:offset_x]
        end

        if grid[:size_y] != 0
          self.y[i] = ((self.y[i] - grid[:offset_y]) / grid[:size_y]).round * grid[:size_y] + grid[:offset_y]
        end

        if self.has_z? && grid[:size_z] != 0
          self.z[i] = ((self.z[i] - grid[:offset_z]) / grid[:size_z]).round * grid[:size_z] + grid[:offset_z]
        end
      end

      cs = self.remove_duplicate_coords
      @ptr = cs.ptr

      self
    end

    def snap_to_grid(*args)
      self.dup.snap_to_grid!(*args)
    end

    def remove_duplicate_coords
      Geos::CoordinateSequence.new(self.to_a.inject([]) { |memo, v|
        memo << v unless memo.last == v
        memo
      })
    end

    protected

      def check_bounds(idx) #:nodoc:
        raise Geos::IndexBoundsError, 'Index out of bounds' if idx.negative? || idx >= length
      end

      def build_coordinate(n) #:nodoc:
        [
          get_x(n),
          (dimensions >= 2 ? get_y(n) : nil),
          (dimensions >= 3 ? get_z(n) : nil)
        ].compact
      end
  end
end
