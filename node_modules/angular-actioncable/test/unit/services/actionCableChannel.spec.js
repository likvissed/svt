'use strict';

describe('ActionCableChannel', function(){
  var ActionCableChannel,
      resetActionCableWebsocketMock,
      ActionCableWebsocket;
  beforeEach(module('ngActionCable'));
  resetActionCableWebsocketMock= function(){
    ActionCableWebsocket= {
      connected: function(){},
      attempt_restart: function(){},
      currentChannels: null,
      close: function(){},
      on_connection_close_callback: function(){},
      on_connection_open_callback: function(){},
      subscribe: function(){},
      unsubscribe: function(){},
      send: function(){}
    };
  };
  beforeEach(function(){
    resetActionCableWebsocketMock();
  });
  var rootScope;
  beforeEach(inject(function(_$rootScope_) {
    rootScope= _$rootScope_;
  }));
  beforeEach(inject(function(_ActionCableChannel_){
    ActionCableChannel= _ActionCableChannel_;
  }));
  it('exists', function(){
    expect(ActionCableChannel).toBeObject;
  });
  describe('onConfirmSubscription', function(){
    var consumer;
    beforeEach(function(){
      consumer= new ActionCableChannel('fooBarChannel')
    });
    it('listens for broadcast', function(){
      var fired= false;
      var callback= function(){ fired= true; };
      consumer.onConfirmSubscription(callback);
      rootScope.$broadcast('confirm_subscription:fooBarChannel');
      expect(fired).toBe(true);
    });
  });
});
