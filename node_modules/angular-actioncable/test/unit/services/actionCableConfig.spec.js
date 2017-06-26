'use strict';

describe('ActionCableConfig', function(){
  var ActionCableConfig;
  beforeEach(module('ngActionCable'));
  beforeEach(inject(function(_ActionCableConfig_){
    ActionCableConfig= _ActionCableConfig_;
  }));
  describe('autoStart', function() {
    it('initiates to true', function(){
      expect(ActionCableConfig.autoStart).toBe(true);
    });
    describe('when set false', function() {
      beforeEach(function() {
        ActionCableConfig.autoStart= false;
      });

      it('remembers false', function(){
        expect(ActionCableConfig.autoStart).toBe(false);
      });
    });
  });
  describe('debug', function() {
    it('initiates to false', function(){
      expect(ActionCableConfig.debug).toBe(false);
    });
    describe('when set true', function() {
      beforeEach(function() {
        ActionCableConfig.debug= true;
      });
      it('remembers true', function(){
        expect(ActionCableConfig.debug).toBe(true);
      });
    });
  });
  describe('wsUri', function() {
    describe('when meta tag set', function() {
      var actionCableMetaTag, metaTags;
      beforeEach(function() {
        actionCableMetaTag= function(attrib){
          if (attrib=== 'name') return 'action-cable-url';
          if (attrib=== 'content') return 'wss://foobar.tld:1234/path/name';
          return false;
        };
        metaTags= [
          { hasAttribute: actionCableMetaTag, getAttribute: actionCableMetaTag }
        ];
        spyOn(document, 'getElementsByTagName').and.returnValue(metaTags);
      });
      it('returns meta value', function(){
        expect(ActionCableConfig.wsUri).toBe('wss://foobar.tld:1234/path/name');
        expect(document.getElementsByTagName).toHaveBeenCalledWith('meta');
      });
    });
    describe('when meta tag not found', function() {
      it('returns helpful example', function(){
        expect(ActionCableConfig.wsUri).toBe('wss://please.add.an.actioncable.meta.tag.invalid:12345/path/to/cable');
      });
    });
    describe('after being explicitly set', function() {
      beforeEach(function() {
        ActionCableConfig.wsUri= 'String 42';
      });
      it('remembers the setting', function(){
        expect(ActionCableConfig.wsUri).toBe('String 42');
      });
    });
  });
});
