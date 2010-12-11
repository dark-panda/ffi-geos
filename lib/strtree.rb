
module Geos
  class STRtree
    include Geos::Tools
    include Enumerable

    attr_reader :ptr

    def initialize(capacity)
      ptr = FFIGeos.GEOSSTRtree_create_r(Geos.current_handle, capacity)

      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      @storage = {}
      @storage_pointers = {}
      @storage_key = 0
      @built = false
    end

    def self.release(ptr)
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
      check_geometry(geom)

      if self.built?
        raise RuntimeError.new("STRtree has already been built")
      else
        key = next_key
        key_ptr = FFI::MemoryPointer.new(:pointer)
        key_ptr.write_int(key)

        @storage[key] = item
        @storage_pointers[key] = key_ptr
        FFIGeos.GEOSSTRtree_insert_r(Geos.current_handle, self.ptr, geom.ptr, key_ptr)
      end
    end

    def remove(geom, item)
      check_geometry(geom)

      key = if @storage.respond_to?(:key)
        @storage.key(item)
      else
        @storage.index(item)
      end

      if key
        key_ptr = @storage_pointers[key]
        result = FFIGeos.GEOSSTRtree_remove_r(Geos.current_handle, self.ptr, geom.ptr, key_ptr)
        @built = true

        if result == 1
          @storage[key] = nil
          @storage_pointers[key] = nil
        end
      end
    end

    def query(geom)
      check_geometry(geom)

      @built = true
      retval = nil

      callback = if block_given?
        proc { |*args|
          key = args.first.read_int
          yield(@storage[key])
        }
      else
        retval = []
        proc { |*args|
          retval << @storage[args.first.read_int]
        }
      end

      FFIGeos.GEOSSTRtree_query_r(
        Geos.current_handle,
        self.ptr,
        geom.ptr,
        callback,
        nil
      )

      if retval
        retval.compact
      end
      retval
    end

    def iterate
      @storage.values.each do |v|
        yield(v)
      end
    end
  end
end
