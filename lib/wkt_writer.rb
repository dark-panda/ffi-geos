
module Geos
  class WktWriter
    attr_reader :ptr
    attr_reader :old_3d
    attr_reader :rounding_precision
    attr_reader :trim

    def initialize(options = {})
      options = {
        :trim => false,
        :old_3d => false,
        :rounding_precision => -1,
        :output_dimensions => 2
      }.merge(options)

      ptr = FFIGeos.GEOSWKTWriter_create_r(Geos.current_handle)
      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      set_options(options)
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKTWriter_destroy_r(Geos.current_handle, ptr)
    end

    def set_options(options) #:nodoc:
      [ :trim, :old_3d, :rounding_precision, :output_dimensions ].each do |k|
        self.send("#{k}=", options[k]) if options.has_key?(k)
      end
    end
    private :set_options

    # Options can be set temporarily for individual writes using an options
    # Hash. Options include :trim, :old_3d, :rounding_precision and
    # :output_dimensions
    def write(geom, options = nil)
      unless options.nil?
        old_options = {
          :trim => self.trim,
          :old_3d => self.old_3d,
          :rounding_precision => self.rounding_precision,
          :output_dimensions => self.output_dimensions
        }

        set_options(options)
      end

      FFIGeos.GEOSWKTWriter_write_r(Geos.current_handle, self.ptr, geom.ptr)
    ensure
      set_options(old_options) unless options.nil?
    end

    def trim=(val)
      @trim = !!val
      FFIGeos.GEOSWKTWriter_setTrim_r(Geos.current_handle, self.ptr,
        @trim ? 1 : 0
      )
    end

    def rounding_precision=(r)
      r = r.to_i
      if r > 255
        raise RuntimeError.new("Rounding precision cannot be greater than 255")
      end

      @rounding_precision = r
      FFIGeos.GEOSWKTWriter_setRoundingPrecision_r(Geos.current_handle, self.ptr, @rounding_precision)
    end

    def old_3d=(val)
      @old_3d = !!val
      FFIGeos.GEOSWKTWriter_setOld3D_r(Geos.current_handle, self.ptr,
        @old_3d ? 1 : 0
      )
    end

    def output_dimensions=(dim)
      dim = dim.to_i
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
