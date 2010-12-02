
module Geos
  class Point < Geometry
    def get_x
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSGeomGetX_r(Geos.current_handle, self.ptr, ret)
      }.get_double(0)
    end
    alias :x :get_x

    def get_y
      FFI::MemoryPointer.new(:pointer).tap { |ret|
        FFIGeos.GEOSGeomGetY_r(Geos.current_handle, self.ptr, ret)
      }.get_double(0)
    end
    alias :y :get_y
  end
end
