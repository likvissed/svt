(function() {
  'use strict';

  app.filter('inventNumsToStr', function() {
    return function(invItemArr) {
      if (!invItemArr) { return; }
      return invItemArr
               .map(function(item) { return item.invent_num; })
               .filter(function(el) { return el; })
               .join('; ');
    }
  });
})();