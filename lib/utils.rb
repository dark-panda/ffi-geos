
module Geos
  module Utils
    def self.orientation_index(ax, ay, bx, by, px, py)
      FFIGeos.GEOSOrientationIndex_r(
        Geos.current_handle,
        ax, ay, bx, by, px, py
      )
    end
  end
end
