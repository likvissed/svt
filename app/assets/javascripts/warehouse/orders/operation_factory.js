(function() {
  'use strict';

  app.factory('WarehouseOperation', WarehouseOperation);

  WarehouseOperation.$inject = [];

  function WarehouseOperation() {
    var
      // Шаблон объекта Operation
      _templateOperation,
      // Поле operation объекта Order
      _order_operation;

    function _getTemplate() {
      return angular.copy(_templateOperation);
    }

    return {
      /**
       * Установить объект _templateOperation
       */
      setTemplate: function(obj, order_operation) {
        _templateOperation = obj;
        // _templateOperation['id'] = obj.warehouse_operation_id;

        _order_operation = order_operation;
       },
      /**
       * Получить объект _templateOperation с заполненными данными
       *
       * @param warehouseType
       * @param item - для операции 'in' это invent_item; для операции 'out' это warehouse_item
       */
      generate: function(warehouseType, item) {
        var obj = _getTemplate();

        if (_order_operation == 'in') {
          if (warehouseType == 'with_invent_num') {
            obj.inv_item = item;
            obj.inv_item_ids = [item.item_id];
            obj.item_type = item.type.short_description;
            obj.item_model = item.get_item_model;
          } else {
            obj.item_type = item.item_type;
            obj.item_model = item.item_model;
          }
        } else if (_order_operation == 'out') {
          obj.inv_item = item.inv_item;
          obj.item_id = item.id;
          obj.item_type = item.item_type;
          obj.item_model = item.item_model;
        } else { return false; }

        return obj;
      }
    }
  }
})();