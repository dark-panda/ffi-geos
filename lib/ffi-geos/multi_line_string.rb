# encoding: UTF-8

module Geos
  class MultiLineString < GeometryCollection
    if FFIGeos.respond_to?(:GEOSisClosed_r) && Geos::GEOS_VERSION >= '3.5.0'
      # Available in GEOS 3.5.0+.
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle, self.ptr))
      end
    end
  end
end
