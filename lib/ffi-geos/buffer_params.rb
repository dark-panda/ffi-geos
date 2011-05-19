
module Geos
  class BufferParams
    include Geos::Tools

    attr_reader :ptr, :params

    VALID_PARAMETERS = [
      :quad_segs, :endcap, :join, :mitre_limit, :single_sided
    ].freeze

    undef :clone, :dup

    # The defaults for the params according to GEOS are as found in
    # Geos::Constants::BUFFER_PARAMS_DEFAULTS. Note that when setting the
    # :quad_segs value that you should set it before setting other values like
    # :join and :mitre_limit, as GEOS contains logic concerning how the
    # :quad_segs value affects these parameters and vice versa. For details,
    # refer to src/operation/buffer/BufferParameters.cpp and the
    # BufferParameters::setQuadrantSegments(int) method in the GEOS source
    # code for details.
    def initialize(params = {})
      params = Geos::Constants::BUFFER_PARAM_DEFAULTS.merge(params)

      ptr = FFIGeos.GEOSBufferParams_create_r(Geos.current_handle)
      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      @params = {}
      VALID_PARAMETERS.each do |param|
        self.send("#{param}=", params[param])
      end
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSBufferParams_destroy_r(Geos.current_handle, ptr)
    end

    def endcap=(value)
      check_enum_value(Geos::BufferCapStyles, value)

      if bool_result(FFIGeos.GEOSBufferParams_setEndCapStyle_r(Geos.current_handle, ptr, value))
        @params[:endcap] = symbol_for_enum(Geos::BufferCapStyles, value)
      end
    end

    def join=(value)
      check_enum_value(Geos::BufferJoinStyles, value)

      if bool_result(FFIGeos.GEOSBufferParams_setJoinStyle_r(Geos.current_handle, ptr, value))
        @params[:join] = symbol_for_enum(Geos::BufferJoinStyles, value)
      end
    end

    def mitre_limit=(value)
      if bool_result(FFIGeos.GEOSBufferParams_setMitreLimit_r(Geos.current_handle, ptr, value))
        @params[:mitre_limit] = value
      end
    end

    def quad_segs=(value)
      if bool_result(FFIGeos.GEOSBufferParams_setQuadrantSegments_r(Geos.current_handle, ptr, value))
        @params[:quad_segs] = value
      end
    end

    def single_sided=(value)
      if bool_result(FFIGeos.GEOSBufferParams_setSingleSided_r(Geos.current_handle, ptr, value ? 1 : 0))
        @params[:single_sided] = value
      end
    end

    VALID_PARAMETERS.each do |param|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{param}
          @params[:#{param}]
        end
      EOF
    end
  end
end
