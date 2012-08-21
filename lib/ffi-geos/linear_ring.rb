
module Geos
  class LinearRing < LineString
    def to_polygon
      Geos.create_polygon(self)
    end
  end
end
