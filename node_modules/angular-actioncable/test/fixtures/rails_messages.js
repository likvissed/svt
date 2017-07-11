'use strict';
var allRailsMessage= {
  five: {
    ping: {
      type: 'ping'
    },
    confirm_subscription: {
      type: 'confirm_subscription',
      identifier: JSON.stringify({'channel': 'fooBarChannel'})
    }
  },
  five_beta_3: {
    ping: {
      identifier: '_ping'
    },
    confirm_subscription: {
      type: 'confirm_subscription',
      identifier: JSON.stringify({'channel': 'fooBarChannel'})
    }
  }
};
var railsVersions= Object.keys(allRailsMessage);
var forEachRailsVersion= function(callback){
  railsVersions.forEach(function(rails_version, index, array){
    describe('Rails', function(){
      describe(rails_version, function(){
        var railsMessage= allRailsMessage[rails_version];
        callback(railsMessage);
      });
    });
  });
};
