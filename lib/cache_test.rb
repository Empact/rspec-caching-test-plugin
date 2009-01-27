# Copyright (c) 2008 Arjan van der Gaag, AG Webdesign
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module AGW #:nodoc:

  # = Rspec caching test plugin
  # 
  # This plugin helps you test your caching with rspec. It provides you with
  # matchers to test if caching and expiring does what you want it to do.
  # 
  # This is basic but useful stuff, extracted from one of my projects. Here's
  # all the matches you'll get:
  # 
  # * <tt>cache_page(url)</tt>
  # * <tt>expire_page(url)</tt>
  # * <tt>cache_action(action)</tt>
  # * <tt>cache_fragment(name)</tt>
  # * <tt>expire_action(action)</tt>
  # * <tt>expire_fragment(name)</tt>
  # 
  # Note that +cache_action+ and +cache_fragment+ are the same thing, only
  # +cache_action+ turns your +action+ argument into the right +name+ using
  # +fragment_cache_key+.
  #
  # == Installation
  #
  # This is almost a drop-in solution. You only need to set up this plugin's
  # test hooks by calling its +setup+ method, preferably in your
  # <tt>spec_helper.rb</tt> file like so:
  #
  #   AGW::CacheTest.setup
  #
  # == Example
  # 
  # Consider the following example specification:
  # 
  #   describe PostsController do
  #     describe "handling GET /posts" do
  #       it "should cache the page" do
  #         lambda { get :index }.should cache_page('/posts')
  #       end
  #   
  #       it "should cache the RSS feed" do
  #         lambda { 
  #           get :index, :format => 'rss' 
  #         }.should cache_page('/posts.rss')
  #       end
  #     end
  #   end
  # 
  # The +cache_page+ matcher tests if your lambda actually triggers the 
  # caching.
  # 
  #   describe "handling GET /users/1" do
  #     it "should cache the action" do
  #       lambda { 
  #         get :show, :id => 1, :user_id => @user.id 
  #       }.should cache_action(:show)
  #     end
  #   end
  # 
  # The +cache_action+ takes a symbol for the action of the current controller
  # to test for, or an entire Hash to be used with +url_for+.
  #
  # Author::    Arjan van der Gaag (info@agwebdesign.nl)
  # Copyright:: copyright (c) 2008 AG Webdesign
  # License::   distributed under the same terms as Ruby.
  module CacheTest
    
    # Call this method to set up this caching mechanism in your code.
    # Ideally this would go into your +spec_helper.rb+.
    #
    # This method enables caching and hooks into the fragment and page
    # caching systems to let all caching flow through this plugin. It also
    # enables the rspec matchers.
    #
    # This method must be called to activate the plugin:
    #
    #   AGW::CacheTest.setup
    # 
    #--
    # TODO: somehow drop this in init.rb
    def self.setup
      # Turn on caching
      ActionController::Base.perform_caching = true

      # Hook into the fragment and page caching mechanisms
      ActionController::Base.cache_store = AGW::CacheTest::TestStore.new
      ActionController::Base.class_eval do
        include AGW::CacheTest::PageCaching
      end
      
      # Make our matchers available to rspec via Test::Unit
      Test::Unit::TestCase.class_eval do
        include Matchers
      end
    end
    

    # This modulse can override the default page caching framework
    # and intercept all caching and expiration requests to keep
    # track of what the apps caches and expires.
    #
    # Methods are added to <tt>ActionController::Base</tt> to test for caching and 
    # expiring (See AGW::CacheTest::PageCaching::InstanceMethods)
    module PageCaching
      module ClassMethods #:nodoc:
        def cache_page(content, path)
         cache_store.write( path, content )
        end

        def expire_page(path)
          cache_store.delete path
        end
      
        def cached?(path)
          cache_store.cached?(path)
        end

        def expired?(path)
          cache_store.expired?(path)
        end
      
        def reset_page_cache!
          cache_store.reset
        end
      end
      
      module InstanceMethods
        # See if the page caching mechanism has cached a given url. This takes
        # the same options as +url_for+.
        def cached?(options = {})
          self.class.cached?(test_cache_url(options))
        end

        # See if the page caching mechanism has expired a given url. This 
        # takes the same options as +url_for+.
        def expired?(options = {})
          self.class.expired?(test_cache_url(options))
        end
        
        private
        
          def test_cache_url(options) #:nodoc:
            url_for(options.merge({ :only_path => true, :skip_relative_url_root => true }))
          end
      end
      
      def self.included(receiver) #:nodoc:
        receiver.class_eval do
          @@test_page_cached  = [] # keep track of what gets cached
          @@test_page_expired = [] # keeg track of what gets expired
          cattr_accessor :test_page_cached
          cattr_accessor :test_page_expired
        end
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
