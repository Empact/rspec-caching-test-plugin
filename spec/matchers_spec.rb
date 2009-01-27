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
  class OtherController < ActionController::Base;end
  
  def initialize_controller(controller_class)
    @controller = controller_class.new
    @controller.process_test ActionController::TestRequest.new :controller => @controller.controller_name
  end
  
  def stub_cache_store
    mock_store = mock('Store',
      :cached => [],
      :expired => [],
      :reset => nil
    )
    ActionController::Base.stub!(:cache_store).and_return(mock_store)
  end
  
  before(:each) do
    stub_cache_store
    initialize_controller MatcherController
  end
  
  # to simulate a controller/integration test environment in which the matchers
  # can access the controller from the example group
  attr_reader :controller

  describe 'for fragment caching' do
    it 'should query the cache store by simple string key with prefix' do
      ActionController::Base.cache_store.should_receive(:cached?).with('views/named_fragment')
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
    it 'should mention fragment in its failure message' do
      expire_fragment('ladida').failure_message.should =~ /fragment/
    end
    
    it 'should mention fragment in its negative failure message' do
      expire_fragment('ladida').negative_failure_message.should =~ /fragment/
    end
    
    it 'should prefix the given fragment name with the standard “views” prefix' do
      ActionController::Base.cache_store.should_receive(:expired?).with('views/hoola-hoop')
      expire_fragment('hoola-hoop').matches?(Proc.new{})
    end
    
    describe 'using an implicit cache key' do
      it 'should query the cache store with the params of the last request' do
        controller.params = {:controller => 'matcher', :action => 'tralala'}
        ActionController::Base.cache_store.should_receive(:expired?).with('views/test.host/matcher/tralala')
        expire_fragment.matches?(Proc.new{})
      end
      
      it 'should use the params after calling the block the matcher matches on' do
        controller.params = {:controller => 'matcher', :action => 'wrong_params'}
        ActionController::Base.cache_store.should_receive(:expired?).with('views/test.host/matcher/right_params')
        expire_fragment.matches?(Proc.new{
          controller.params = {:controller => 'matcher', :action => 'right_params'}
        })
      end
      
      it 'should use the controller after calling the block so matching works in integration tests' do
        initialize_controller(MatcherController)
        ActionController::Base.cache_store.should_receive(:expired?).with('views/test.host/other')
        expire_fragment.matches?(Proc.new{
          initialize_controller(OtherController)
        })
      end
    end
  end
  
  describe 'for action expiration' do
    it 'should mention “action” in its failure message' do
      expire_action(:update).failure_message.should =~ /expire\ action/
    end
    
    it 'should mention “action” in its negative failure message' do
      expire_action(:update).negative_failure_message.should =~ /expire\ action/
    end
  end
  
end
