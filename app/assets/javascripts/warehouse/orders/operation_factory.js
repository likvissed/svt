(function() {
  'use strict';

  app.factory('WarehouseOperation', WarehouseOperation);

  WarehouseOperation.$inject = [];

  function WarehouseOperation() {
    var _templateOperation;

    function _getTemplate() {
      return angular.copy(_templateOperation);
    }

    return {
      /**
       * Установить объект _templateOperation
       */
      setTemplate: function(obj) {
        _templateOperation = obj;
        _templateOperation['id'] = obj.warehouse_operation_id;
       },
      /**
       * Получить объект _templateOperation с заполненными данными
       *
       * @param type
       * @param item
       */
      generate: function(type, item) {
        var obj = _getTemplate();
        console.log(item);

        if (type == 'returnable') {
          obj.inv_item = item;
          obj.invent_item_id = item.item_id;
          obj.item_type = item.type.short_description;
          obj.item_model = item.model ? item.model.item_model : item.item_model;
        } else {
          obj.item_type = item.item_type;
          obj.item_model = item.item_model;
        }

        return obj;
      }
    }
  }
})();