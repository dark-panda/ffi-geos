
module Geos
  class STRtree
    include Geos::Tools
    include Enumerable

    attr_reader :ptr

    undef :clone, :dup

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

        geoms_and_objects.each do |geom, obj|
          check_geometry(geom)
        end

        geoms_and_objects.length
      end

      if capacity <= 0
        raise ArgumentError.new("STRtree capacity must be greater than 0")
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
          self.insert(geom, obj)
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
        raise RuntimeError.new("STRtree has already been built")
      else
        check_geometry(geom)

        key = next_key
        key_ptr = FFI::MemoryPointer.new(:pointer)
        key_ptr.write_int(key)

        @storage[key] = {
          :item => item,
          :geometry => geom
        }
        @ptrs[key] = key_ptr

        FFIGeos.GEOSSTRtree_insert_r(Geos.current_handle, self.ptr, geom.ptr, key_ptr)
      end
    end

    def remove(geom, item)
      check_geometry(geom)

      key = if storage = @storage.detect { |k, v| v[:item] == item }
        storage[0]
      end

      if key
        key_ptr = @ptrs[key]
        result = FFIGeos.GEOSSTRtree_remove_r(Geos.current_handle, self.ptr, geom.ptr, key_ptr)
        @built = true

        if result == 1
          @storage.delete(key)
        end
      end
    end

    def query_all(geom)
      check_geometry(geom)

      @built = true
      retval = []

      callback = proc { |*args|
        key = args.first.read_int
        storage = @storage[key]
        retval << storage

        if block_given?
          yield(storage)
        end
      }

      FFIGeos.GEOSSTRtree_query_r(
        Geos.current_handle,
        self.ptr,
        geom.ptr,
        callback,
        nil
      )

      retval
    end

    def query(geom, ret = :item)
      self.query_all(geom).collect { |storage|
        item = if ret.is_a?(Array)
          storage.inject({}) do |memo, k|
            memo.tap {
              memo[k] = storage[k]
            }
          end
        elsif ret == :all
          storage
        else
          storage[ret]
        end

        item.tap {
          if block_given?
            yield(item)
          end
        }
      }.compact
    end

    def query_geometries(geom)
      self.query_all(geom).collect { |storage|
        storage[:geometry].tap { |val|
          if block_given?
            yield(val)
          end
        }
      }.compact
    end
    alias :query_geoms :query_geometries

    def iterate
      @storage.values.each do |v|
        yield(v)
      end
    end
  end
end
