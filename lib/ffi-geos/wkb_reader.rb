# encoding: UTF-8

module Geos
  class WkbReader
    include Geos::Tools

    attr_reader :ptr

    def initialize(*args)
      ptr = if args.first.is_a?(FFI::Pointer)
        args.first
      else
        FFIGeos.GEOSWKBReader_create_r(Geos.current_handle, *args)
      end

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )
    end

    def read(wkb, options = {})
      cast_geometry_ptr(FFIGeos.GEOSWKBReader_read_r(Geos.current_handle, self.ptr, wkb, wkb.bytesize), {
        :srid => options[:srid]
      })
    end

    def read_hex(wkb, options = {})
      cast_geometry_ptr(FFIGeos.GEOSWKBReader_readHEX_r(Geos.current_handle, self.ptr, wkb, wkb.bytesize), {
        :srid => options[:srid]
      })
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKBReader_destroy_r(Geos.current_handle, ptr)
    end
  end
end
