(function() {
  'use strict';

  app.factory('WarehouseItem', WarehouseItem);

  WarehouseItem.$inject = [];

  function WarehouseItem() {
    var _templateItem;

    return {
      /**
       * Установить объект _templateOperation
       */
    setTemplate: function(obj) {
        _templateItem = obj;
        _templateItem['id'] = obj['warehouse_item_to_order_id'];
    },
      /**
       * Получить объект _templateOperation
       */
    getTemplate: function() { return angular.copy(_templateItem); }
  }
}
})();