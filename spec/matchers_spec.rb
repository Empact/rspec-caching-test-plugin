require 'spec'
require 'actionpack'
require 'action_controller'
require 'action_controller/test_process'
require File.join(File.dirname(__FILE__),'..','lib','matchers')


describe 'Matchers' do
  include AGW::CacheTest::Matchers
  
  ActionController::Routing::Routes.draw do |map|
    map.connect ':controller/:action/:id'
  end
  class MatcherController < ActionController::Base;end
  before(:each) do
    mock_store = mock('Store', :reset => nil)
    ActionController::Base.stub!(:cache_store).and_return(mock_store)
    
    @controller = MatcherController.new
    @controller.process_test ActionController::TestRequest.new
  end
  
  # to simulate a controller/integration test environment in which the matchers
  # can access the controller from the example group
  attr_reader :controller

  describe 'fragment caching' do
    it 'should query the cache store by simple string key' do
      ActionController::Base.cache_store.should_receive(:cached?).with('named_fragment')
      cache_fragment('named_fragment').matches?(Proc.new{})
    end
    
    it 'should query the cache store by create cache generated from a params hash' do
      ActionController::Base.cache_store.should_receive(:cached?).with('views/test.host/matcher/ladida')
      cache_fragment(:controller => 'matcher', :action => 'ladida').matches?(Proc.new{})
    end
    
    it 'should query the cache store with the params of the last request
    when using the implicit cache key in the matcher' do
      controller.params = {:controller => 'matcher', :action => 'tralala'}
      ActionController::Base.cache_store.should_receive(:cached?).with('views/test.host/matcher/tralala')
      cache_fragment.matches?(Proc.new{})
    end
  end
  
end
