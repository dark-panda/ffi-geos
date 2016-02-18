# encoding: UTF-8

module Geos
  class STRtree
    include Geos::Tools
    include Enumerable

    attr_reader :ptr

    undef :clone, :dup

    class AlreadyBuiltError < Geos::Error
      def initialize(*)
        super('STRtree has already been built')
      end
    end

    # :call-seq:
    #   new(capacity)
    #   new(geoms_and_objects)
    #
    def initialize(*args)
      geoms_and_objects = nil # forward declaration

      capacity = if args.length == 1 && args.first.is_a?(Fixnum)
                   args.first
                 else
                   geoms_and_objects = if args.first.first.is_a?(Array)
                                         args.first
                                       else
                                         args
                   end

                   geoms_and_objects.each do |geom, _obj|
                     check_geometry(geom)
                   end

                   geoms_and_objects.length
      end

      if capacity <= 0
        fail ArgumentError.new('STRtree capacity must be greater than 0')
      end

      ptr = FFIGeos.GEOSSTRtree_create_r(Geos.current_handle, capacity)

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      @storage = {}
      @ptrs = {}

      @storage_key = 0
      @built = false

      if geoms_and_objects
        geoms_and_objects.each do |geom, obj|
          insert(geom, obj)
        end
      end
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSSTRtree_destroy_r(Geos.current_handle, ptr)
    end

    def built?
      @built
    end

    def next_key
      @storage_key += 1
    end
    private :next_key

    def insert(geom, item)
      if self.built?
        fail AlreadyBuiltError.new
      else
        check_geometry(geom)

        key = next_key
        key_ptr = FFI::MemoryPointer.new(:pointer)
        key_ptr.write_int(key)

        @storage[key] = {
          item: item,
          geometry: geom
        }
        @ptrs[key] = key_ptr

        FFIGeos.GEOSSTRtree_insert_r(Geos.current_handle, ptr, geom.ptr, key_ptr)
      end
    end

    def remove(geom, item)
      check_geometry(geom)

      key = if storage = @storage.detect { |_k, v| v[:item] == item }
              storage[0]
      end

      if key
        key_ptr = @ptrs[key]
        result = FFIGeos.GEOSSTRtree_remove_r(Geos.current_handle, ptr, geom.ptr, key_ptr)
        @built = true

        @storage.delete(key) if result == 1
      end
    end

    def query_all(geom)
      check_geometry(geom)

      @built = true
      retval = []

      callback = proc do |*args|
        key = args.first.read_int
        storage = @storage[key]
        retval << storage

        yield(storage) if block_given?
      end

      FFIGeos.GEOSSTRtree_query_r(
        Geos.current_handle,
        ptr,
        geom.ptr,
        callback,
        nil
      )

      retval
    end

    def query(geom, ret = :item)
      query_all(geom).collect do |storage|
        item = if ret.is_a?(Array)
                 storage.inject({}) do |memo, k|
                   memo.tap do
                     memo[k] = storage[k]
                   end
                 end
               elsif ret == :all
                 storage
               else
                 storage[ret]
        end

        item.tap do
          yield(item) if block_given?
        end
      end.compact
    end

    def query_geometries(geom)
      query_all(geom).collect do |storage|
        storage[:geometry].tap do |val|
          yield(val) if block_given?
        end
      end.compact
    end
    alias_method :query_geoms, :query_geometries

    def iterate
      @storage.values.each do |v|
        yield(v)
      end
    end
  end
end
