'use strict';
describe('ActionCableController', function(){
  var ActionCableController;
  beforeEach(module('ngActionCable'));
  beforeEach(inject(function(_ActionCableController_){
    ActionCableController= _ActionCableController_;
  }));
  var rootScope;
  beforeEach(inject(function($injector) {
    rootScope = $injector.get('$rootScope');
    spyOn(rootScope, '$broadcast');
  }));
  it('exists', function(){
    expect(ActionCableController).toBeObject;
  });
  describe('subscription', function(){
    forEachRailsVersion(function(railsMessage){
      it('broadcasts', function(){
        ActionCableController.post(railsMessage['confirm_subscription']);
        expect(rootScope.$broadcast).toHaveBeenCalledWith('confirm_subscription:fooBarChannel');
      });
    });
  });
  describe('ping', function(){
    forEachRailsVersion(function(railsMessage){
      it('after_ping_callback', function(){
        var fired= false;
        var callback= function(){ fired= true; };
        ActionCableController.after_ping_callback= callback;
        ActionCableController.post(railsMessage['ping']);
        expect(fired).toBe(true);
      });
    });
  });
});
