(function() {
  'use strict';

  app.factory('Operation', Operation);

  Operation.$inject = [];

  function Operation() {
    var _templateOperation;

    return {
      /**
       * Установить объект _templateOperation
       */
      setTemplate: function(obj) { 
        _templateOperation = obj;
        _templateOperation['id'] = obj['warehouse_operation_id'];
       },
      /**
       * Получить объект _templateOperation
       */
      getTemplate: function() { return angular.copy(_templateOperation); }
    }
  }
})();