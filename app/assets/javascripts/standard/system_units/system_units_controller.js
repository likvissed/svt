(function(){
  'use strict';

  app
    .controller('SystemUnitIndexCtrl', SystemUnitIndexCtrl);

  SystemUnitIndexCtrl.$inject = ['NgTableParams'];

  function SystemUnitIndexCtrl(NgTableParams) {
    var self = this;

    // var data = [{ name: "Moroni", age: 50 }, { name: "Katty", age: 32 }];

    // self.tableParams = new NgTableParams({}, { dataset: data });
  }
})();