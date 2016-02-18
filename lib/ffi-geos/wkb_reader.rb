# encoding: UTF-8

module Geos
  class WkbReader
    include Geos::Tools

    attr_reader :ptr

    class ParseError < Geos::ParseError
    end

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
      cast_geometry_ptr(FFIGeos.GEOSWKBReader_read_r(Geos.current_handle, ptr, wkb, wkb.bytesize), srid: options[:srid])
    rescue Geos::GEOSException => e
      raise ParseError.new(e)
    end

    def read_hex(wkb, options = {})
      cast_geometry_ptr(FFIGeos.GEOSWKBReader_readHEX_r(Geos.current_handle, ptr, wkb, wkb.bytesize), srid: options[:srid])
    rescue Geos::GEOSException => e
      raise ParseError.new(e)
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKBReader_destroy_r(Geos.current_handle, ptr)
    end
  end
end
