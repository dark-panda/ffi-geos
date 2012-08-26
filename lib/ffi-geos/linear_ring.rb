
module Geos
  class LinearRing < LineString
    def to_polygon
      Geos.create_polygon(self, :srid => pick_srid_according_to_policy(self.srid))
    end
  end
end
