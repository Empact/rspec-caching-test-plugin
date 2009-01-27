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
    mock_store = mock('Store',
      :cached => [],
      :reset => nil
    )
    ActionController::Base.stub!(:cache_store).and_return(mock_store)
    
    @controller = MatcherController.new
    @controller.params = {:controller => @controller.controller_name}
    @controller.process_test ActionController::TestRequest.new
  end
  
  # to simulate a controller/integration test environment in which the matchers
  # can access the controller from the example group
  attr_reader :controller

  describe 'for fragment caching' do
    it 'should query the cache store by simple string key' do
      ActionController::Base.cache_store.should_receive(:cached?).with('named_fragment')
      cache_fragment('named_fragment').matches?(Proc.new{})
    end
    
    it 'should query the cache store by create cache generated from a params hash' do
      ActionController::Base.cache_store.should_receive(:cached?).with('views/test.host/matcher/ladida')
      cache_fragment(:controller => 'matcher', :action => 'ladida').matches?(Proc.new{})
    end
    
    describe 'using an implicit cache key' do
      it 'should query the cache store with the params of the last request' do
        controller.params = {:controller => 'matcher', :action => 'tralala'}
        ActionController::Base.cache_store.should_receive(:cached?).with('views/test.host/matcher/tralala')
        cache_fragment.matches?(Proc.new{})
      end
      
      it 'should use the params after calling the block the matcher ' do
        controller.params = {:controller => 'matcher', :action => 'wrong_params'}
        ActionController::Base.cache_store.should_receive(:cached?).with('views/test.host/matcher/right_params')
        cache_fragment.matches?(Proc.new{
          controller.params = {:controller => 'matcher', :action => 'right_params'}
        })
      end
    end
    
    it 'should mention fragment in its failure message' do
      cache_fragment('ladida').failure_message.should =~ /fragment/
    end
    
    it 'should mention fragment in its negative failure message' do
      cache_fragment('ladida').negative_failure_message.should =~ /fragment/
    end
  end
  
  describe 'for action caching' do
    it 'should mention “action” in its failure message' do
      cache_action(:update).failure_message.should =~ /cache\ action/
    end
    
    it 'should mention “action” in its negative failure message' do
      cache_action(:update).negative_failure_message.should =~ /cache\ action/
    end
  end
  
  describe 'for fragment expiration' do
    describe 'using an implicit cache key' do
      it 'should query the cache store with the params of the last request' do
        controller.params = {:controller => 'matcher', :action => 'tralala'}
        ActionController::Base.cache_store.should_receive(:expired?).with('views/test.host/matcher/tralala')
        expire_fragment.matches?(Proc.new{})
      end
      
      it 'should use the params after calling the block the matcher ' do
        controller.params = {:controller => 'matcher', :action => 'wrong_params'}
        ActionController::Base.cache_store.should_receive(:expired?).with('views/test.host/matcher/right_params')
        expire_fragment.matches?(Proc.new{
          controller.params = {:controller => 'matcher', :action => 'right_params'}
        })
      end
    end
  end
  
end
