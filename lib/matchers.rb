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
        def initialize(name, example_group, type=:fragment)
          @name       = name
          @example_group = example_group
          @type = type
          ActionController::Base.cache_store.reset
        end
        
        def matches?(block)
          block.call
          @controller = @example_group.controller
          @key = cache_key_for_name(@name)
          query_cache_store(@key)
        end
        
        def failure_message
          "Expected block to #{failure_action} #{@type} #{@name.inspect} (#{@key}), but #{failure_reason}"
        end

        def negative_failure_message
          "Expected block not to #{failure_action} #{@type} #{@name.inspect} (#{@key})"
        end
        
      private
        # override this method in the concrete subclasses
        def query_cache_store(key)
          raise NotImplementedError
        end
      
        def cache_key_for_name(name)
          if @type == :action && !name.is_a?(Hash)
            name = { :action => name, :controller => @controller.controller_name }
          end
          @controller.fragment_cache_key(name || @controller.params)
        end
      end
      
      class CachingMatcher < AbstractCacheMatcher #:nodoc:
      private
        def failure_reason
          if ActionController::Base.cache_store.cached.any?
            "the cache only has #{ActionController::Base.cache_store.cached.to_yaml}."
          else
            "the cache is empty."
          end
        end
        
        def failure_action
          'cache'
        end
      
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
        CachingMatcher.new(action, self, :action)
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
        CachingMatcher.new(name, self)
      end
      alias_method :cache_fragment, :cache
      
      class ExpirationMatcher < AbstractCacheMatcher #:nodoc:
      private
        def failure_reason
          if ActionController::Base.cache_store.expired.any?
            "the cache has only expired #{ActionController::Base.cache_store.expired.to_yaml}."
          else
            "nothing was expired."
          end
        end
        
        def failure_action
          'expire'
        end
        
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
      def expire_action(action)
        ExpirationMatcher.new(action, self, :action)
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
        ExpirationMatcher.new(name, self)
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
