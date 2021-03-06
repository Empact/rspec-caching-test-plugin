if RAILS_ENV == 'test'
  require 'cache_test'
  require 'matchers'
  require 'test_store'
  
  # Turn on caching
  ActionController::Base.perform_caching = true

  # Hook into the fragment and page caching mechanisms
  ActionController::Base.cache_store = AGW::CacheTest::TestStore.new
  ActionController::Base.class_eval do
    include AGW::CacheTest::PageCaching
  end
end
