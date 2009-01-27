module AGW
  module CacheTest
    # The rspec matchers give do the actual testing of your logic. These
    # matchers work on a block of code and take a URL, action or name as
    # argument. They all work in more or less the same way.
    #
    # Note that although these matchers are written for rspec, the
    # underlying concepts can easily be applied to <tt>Test::Unit</tt> or
    # something else.
    module Matchers
      class AbstractCacheMatcher #:nodoc:
        def initialize(name, controller, type=:fragment)
          @name       = name
          @controller = controller
          @type = type
          ActionController::Base.cache_store.reset
        end
        
        def matches?(block)
          block.call
          @key = cache_key_for_name(@name)
          query_cache_store(@key)
        end
        
      private
        # override this method in the concrete subclasses
        def query_cache_store(key)
          raise NotImplementedError
        end
      
        def cache_key_for_name(name)
          return @controller.fragment_cache_key(@controller.params) unless name
          if @type == :action && !name.is_a?(Hash)
            name = { :action => name, :controller => @controller.controller_name }
          end
          name.is_a?(String) ? name : @controller.fragment_cache_key(name)
        end
      end
      
      class TestCacheCaches < AbstractCacheMatcher #:nodoc:
        def failure_message
          reason = if ActionController::Base.cache_store.cached.any?
            "the cache only has #{ActionController::Base.cache_store.cached.to_yaml}."
          else
            "the cache is empty."
          end
          "Expected block to cache #{@type} #{@name.inspect} (#{@key}), but #{reason}"
        end

        def negative_failure_message
          "Expected block not to cache #{@type} #{@name.inspect} (#{@key})"
        end
      private
        def query_cache_store(key)
          ActionController::Base.cache_store.cached?(key)
        end
      end

      # See if an acion gets cached
      #
      # Usage:
      #
      #   lambda { get :index }.should cache_action(:index)
      # 
      # You can pass in the name of an action which will then get
      # interpreted in the context of the current controller. Alternatively,
      # you can pass in a whole +Hash+ for +url_for+ defining all your
      # paramaters.
      def cache_action(action)
        TestCacheCaches.new(action, controller, :action)
      end
      
      # See if a fragment gets cached.
      #
      # The name you pass in can be any name you have given your fragment.
      # This would typically be a +String+.
      # If you don't pass in a cache key it will take the params from the last
      # request to generate a key, similar to calling
      # ActionView::Helpers::CacheHelper#cache without arguments, e.g. in a 
      # +cache do … end+ block in your view.
      # It will also generate a 
      #
      # Usage:
      #
      #   lambda { get :index }.should cache('my_caching')
      #
      #   lambda { get :index }.should cache
      # 
      def cache(name=nil)
        TestCacheCaches.new(name, controller)
      end
      alias_method :cache_fragment, :cache
      
      class TestCacheExpires < AbstractCacheMatcher #:nodoc:
        def failure_message
          reason = if ActionController::Base.cache_store.expired.any?
            "the cache has only expired #{ActionController::Base.cache_store.expired.to_yaml}."
          else
            "nothing was expired."
          end
          "Expected block to expire action #{@name.inspect} (#{@key}), but #{reason}"
        end

        def negative_failure_message
          "Expected block not to expire #{@name.inspect} (#{@key})"
        end
      private
        def query_cache_store(key)
          ActionController::Base.cache_store.expired?(key)
        end
      end

      # See if an action is expired
      #
      # Usage:
      # 
      #   lambda { get :index }.should expire_action(:index)
      # 
      # You can pass in the name of an action which will then get
      # interpreted in the context of the current controller. Alternatively,
      # you can pass in a whole +Hash+ for +url_for+ defining all your
      # paramaters.
      #
      # This is a shortcut method to +expire+.
      def do_expire_action(action)
        action = { :action => action } unless action.is_a?(Hash)
        expire(action)
      end

      # See if a fragment is expired
      #
      # The name you pass in can be any name you have given your fragment.
      # This would typically be a +String+.
      #
      # Usage:
      # 
      #   lambda { get :index }.should expire('my_cached_something')
      # 
      def expire(name=nil)
        TestCacheExpires.new(name, controller)
      end
      alias_method :expire_fragment, :expire
      
      class CachePage #:nodoc:
        def initialize(url)
          @url = url
          ActionController::Base.reset_page_cache!
        end
        
        # See if +ActionController::Base+ was told to cache our page.
        def matches?(block)
          block.call
          return ActionController::Base.cached?(@url)
        end

        def failure_message
          if ActionController::Base.cache_store.cached.any?
            "Expected block to cache the page #{@url.inspect} but it only cached #{ActionController::Base.cache_store.cached.to_yaml}"
          else
            "Expected block to expire the page #{@url.inspect} but it cached nothing"
          end
        end

        def negative_failure_message
          "Expected block not to cache the page #{@url.inspect}"
        end
      end

      # See if a page URL (or relative path) gets cached
      #
      # Usage:
      #
      #   lambda { get :index }.should cache_page('/posts')
      # 
      def cache_page(url)
        CachePage.new(url)
      end

      class ExpirePage #:nodoc:
        def initialize(url)
          @url = url
          ActionController::Base.reset_page_cache!
        end

        def matches?(block)
          block.call 
          return ActionController::Base.cache_store.expired?(@url)
        end

        def failure_message
          if ActionController::Base.cache_store.expired.any?
            "Expected block to expire the page #{@url.inspect} but it only expired #{ActionController::Base.cache_store.expired.to_yaml}"
          else
            "Expected block to expire the page #{@url.inspect} but it expired nothing"
          end
        end

        def negative_failure_message
          "Expected block not to expire the page #{@url.inspect}"
        end
      end

      # See if a page URL (or relative path) gets expired
      #
      # Usage:
      #
      #   lambda { get :index }.should expire_page('/posts')
      # 
      def expire_page(url)
        ExpirePage.new(url)
      end
    end
  end
end
