# encoding: UTF-8

# This file adds yaml serialization support to geometries.  The generated yaml
# has this format:
#
#    !ruby/object:Geos::Geometry
#    wkt: POINT (-104.97 39.71)
#    srid: 4326
#
#  So to use this in a rails fixture file you could do something like this:
#
#    geometry_1:
#      id: 1
#      geom: !ruby/object:Geos::Geometry
#        wkt: POINT (-104.97 39.71)
#        srid: 4326
#
# Note this code assumes the use of Psych (not syck) and ruby 1.9 and higher

require 'yaml'

module Geos
  class Geometry
    def init_with(coder)
      # Convert wkt to a geos pointer
      reader = Geos::WktReader.new
      geom_ptr = FFIGeos.GEOSWKTReader_read_r(Geos.current_handle, reader.ptr, coder['wkt'])

      # Now setup this objects pointer to be the pointer we just created
      @ptr = FFI::AutoPointer.new(geom_ptr, self.class.method(:release))
      self.srid = coder['srid']
    end

    def encode_with(coder)
      writer = Geos::WktWriter.new
      # Note we enforce ascii encoding so the wkt in the yaml file is readable - otherwise
      # psych converts it to a binary string
      coder['wkt'] = writer.write(self).force_encoding('ASCII')
      coder['srid'] = self.srid
    end
  end
end