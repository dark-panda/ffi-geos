# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class Point < Geometry
    if FFIGeos.respond_to?(:GEOSGeomGetX_r)
      def get_x
        double_ptr = FFI::MemoryPointer.new(:double)
        FFIGeos.GEOSGeomGetX_r(Geos.current_handle_pointer, self.ptr, double_ptr)
        double_ptr.read_double
      end
    else
      def get_x
        self.coord_seq.get_x(0)
      end
    end
    alias_method :x, :get_x

    if FFIGeos.respond_to?(:GEOSGeomGetY_r)
      def get_y
        double_ptr = FFI::MemoryPointer.new(:double)
        FFIGeos.GEOSGeomGetY_r(Geos.current_handle_pointer, self.ptr, double_ptr)
        double_ptr.read_double
      end
    else
      def get_y
        self.coord_seq.get_y(0)
      end
    end
    alias_method :y, :get_y

    if FFIGeos.respond_to?(:GEOSGeomGetZ_r)
      def get_z
        double_ptr = FFI::MemoryPointer.new(:double)
        FFIGeos.GEOSGeomGetZ_r(Geos.current_handle_pointer, self.ptr, double_ptr)
        double_ptr.read_double
      end
    else
      def get_z
        self.coord_seq.get_z(0)
      end
    end
    alias_method :z, :get_z

    def area
      0
    end

    def length
      0
    end

    def num_geometries
      1
    end

    def num_coordinates
      1
    end

    def normalize!
      self
    end
    alias_method :normalize, :normalize!

    %w{
      convex_hull
      point_on_surface
      centroid
      envelope
      topology_preserve_simplify
    }.each do |method|
      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def #{method}(*args)
          self.dup.tap { |ret|
            ret.srid = pick_srid_according_to_policy(ret.srid)
          }
        end
      EOF
    end
  end
end
