(function() {
  'use strict';

  app.factory('ItemToOrder', ItemToOrder);

  ItemToOrder.$inject = [];

  function ItemToOrder() {
    var _templateIO;

    return {
      /**
       * Установить объект _templateOperation
       */
      setTemplate: function(obj) {
        _templateIO = obj;
        _templateIO['id'] = obj['warehouse_item_to_order_id'];
      },
      /**
       * Получить объект _templateOperation
       */
      getTemplate: function() { return angular.copy(_templateIO); }
    }
  }
})();