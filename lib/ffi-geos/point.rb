
module Geos
  class Point < Geometry
    if FFIGeos.respond_to?(:GEOSGeomGetX_r)
      def get_x
        FFI::MemoryPointer.new(:double).tap { |ret|
          FFIGeos.GEOSGeomGetX_r(Geos.current_handle, self.ptr, ret)
        }.read_double
      end
      alias :x :get_x
    end

    if FFIGeos.respond_to?(:GEOSGeomGetY_r)
      def get_y
        FFI::MemoryPointer.new(:double).tap { |ret|
          FFIGeos.GEOSGeomGetY_r(Geos.current_handle, self.ptr, ret)
        }.read_double
      end
      alias :y :get_y
    end
  end
end
