
module Geos
  class Point < Geometry
    if FFIGeos.respond_to?(:GEOSGeomGetX_r)
      def get_x
        FFI::MemoryPointer.new(:double).tap { |ret|
          FFIGeos.GEOSGeomGetX_r(Geos.current_handle, self.ptr, ret)
        }.read_double
      end
    else
      def get_x
        self.coord_seq.get_x(0)
      end
    end
    alias :x :get_x

    if FFIGeos.respond_to?(:GEOSGeomGetY_r)
      def get_y
        FFI::MemoryPointer.new(:double).tap { |ret|
          FFIGeos.GEOSGeomGetY_r(Geos.current_handle, self.ptr, ret)
        }.read_double
      end
    else
      def get_y
        self.coord_seq.get_y(0)
      end
    end
    alias :y :get_y

    if FFIGeos.respond_to?(:GEOSGeomGetZ_r)
      def get_z
        FFI::MemoryPointer.new(:double).tap { |ret|
          FFIGeos.GEOSGeomGetZ_r(Geos.current_handle, self.ptr, ret)
        }.read_double
      end
    else
      def get_z
        self.coord_seq.get_z(0)
      end
    end
    alias :z :get_z
  end
end
