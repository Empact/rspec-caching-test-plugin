module AGW
  module CacheTest
    # This class is the cache store used during testing. All fragment caching
    # requests come to here. It tells us what was cached and what was
    # expired by the application.
    #
    # == Usage
    #
    # The application uses this class in its caching. In tests we can
    # ask the class about this as follows:
    #
    #   @test_store = TestStore.new
    #   ...trigger caching...
    #   @test_store.cached?('my_page') # => true
    #   @test_store.expired?('my_page') # => false
    #   ...trigger expiration...
    #   @test_store.expired?('my_page') # => true
    # 
    # == Perform the actual caching
    #
    # This test cache store can actually cache content, but by default
    # does not. If it caches and returns cached content this might affect
    # your tests, forcing you to reset the cache for every test so as to
    # get the desired behaviour.
    #
    # The default behaviour is set on creation of the TestStore by
    # passing in a simple flag. You can, however, change this at run time
    # like so:
    #
    #   @a = TestStore.new       # => caching is off
    #   @a.read_cache = true     # => caching is on
    #   
    #   @b = TestStore.new(true) # => caching is on
    #   @b.read_cache = false    # => caching is off
    #
    # When needed the cache can be cleared manually like so:
    #
    #   ActionController::Base.cache_store.reset
    # 
    class TestStore < ActiveSupport::Cache::Store

      # Record of what the app tells us to cache
      attr_reader :cached
      
      # Record of what the app tells us to expire
      attr_reader :expired
      
      # Record of what the app tells us to expire via patterns
      attr_reader :expiration_patterns
      
      # Cached data that could be returned
      attr_reader :data
      
      # Setting to enable the returning of cached data.
      attr_accessor :read_cache

      def initialize(do_read_cache = false) #:nodoc:
        @data                = {}
        @cached              = []
        @expired             = []
        @expiration_patterns = []
        @read_cache          = do_read_cache
      end
      
      # Reset the cache store, effectively emptying the cache
      def reset
        @data.clear
        @cached.clear
        @expired.clear
        @expiration_patterns.clear
      end

      def read(name, options = nil) #:nodoc:
        super
        read_cache ? @data[name] : nil
      end

      def write(name, value, options = nil) #:nodoc:
        super
        
        # Actually store the data if desired
        @data[name] = value if read_cache
        
        # Record this caching
        @cached << name
      end

      def delete(name, options = nil) #:nodoc:
        logger.info("TestStore: deleted #{name} from cache")
        super
        @expired << name
      end

      def delete_matched(matcher, options = nil) #:nodoc:
        super
        @expiration_patterns << matcher
      end

      # See if a given name was written to the cache
      def cached?(name)
        @cached.include?(name)
      end
      
      # See if a given name was expired from the cache, eiter directly or
      # using an expiration pattern.
      def expired?(name)
        @expired.include?(name) || @expiration_patterns.detect { |matcher| name =~ matcher }
      end

    end
  end
end
