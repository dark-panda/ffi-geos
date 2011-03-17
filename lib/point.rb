
module Geos
  class Point < Geometry
    def get_x
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSGeomGetX_r(Geos.current_handle, self.ptr, ret)
      }.read_double
    end
    alias :x :get_x

    def get_y
      FFI::MemoryPointer.new(:double).tap { |ret|
        FFIGeos.GEOSGeomGetY_r(Geos.current_handle, self.ptr, ret)
      }.read_double
    end
    alias :y :get_y
  end
end
