import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .factory('WarehouseOperation', WarehouseOperation);

  WarehouseOperation.$inject = [];

  function WarehouseOperation() {
    let
      // Шаблон объекта Operation
      _templateOperation,
      // Поле operation объекта Order
      _orderOperation;

    function _getTemplate() {
      return angular.copy(_templateOperation);
    }

    function _setData(op, data) {
      op.shift = data.shift;
      op.item = op.item || {};
      op.item.warehouse_type = data.warehouseType;
      op.item.invent_type_id = data.type.type_id || null;
      op.item.invent_model_id = data.model.model_id || null;
      op.item.item_type = data.type.short_description;
      op.item.item_model = data.model.item_model;
      op.item.barcode = data.barcode;
      op.item.invent_num_start = data.inventNumStart;
      op.item.invent_num_end = data.inventNumEnd;
    }


    function _generateOrder(warehouseType, item) {
      let op = _getTemplate();

      if (_orderOperation == 'in') {
        if (warehouseType == 'with_invent_num') {
          op.inv_items = [item];
          op.inv_item_ids = [item.item_id];
          op.item_type = item.type.short_description;
          op.item_model = item.full_item_model;
        } else {
          op.item_type = item.item_type;
          op.item_model = item.item_model;
        }
      } else if (_orderOperation == 'out' || _orderOperation == 'write_off') {
        op.item_id = item.id;
        op.item_type = item.item_type;
        op.item_model = item.item_model;
      } else { return false; }

      return op;
    }

    function _generateSupply(data) {
      let op = _getTemplate();

      _setData(op, data);

      return op;
    }

    return {
      /**
       * Установить объект _templateOperation
       *
       * @param obj - шаблон operation
       * @param order_operation - тип ордера (если это ордер)
       */
      setTemplate: function(obj, order_operation) {
        _templateOperation = obj;
        _orderOperation = order_operation;
       },
       /**
        * Получить шаблон позиции
        */
       getTemplate: function() { return _templateOperation; },
      /**
       * Получить объект _templateOperation с заполненными данными
       *
       * @param warehouseType
       * @param item - Для Order: для операции 'in' это invent_item; для операции 'out' это warehouse_item. Для Supply - параметры для warehouse_item и operation.
       */
      generate: function(warehouseType, item) {
        if (_templateOperation.operationable_type == 'Warehouse::Order') {
          return _generateOrder(warehouseType, item);
        } else if (_templateOperation.operationable_type == 'Warehouse::Supply') {
          return _generateSupply(item);
        }
      },
      update: function(op, data) {
        if (_templateOperation.operationable_type == 'Warehouse::Supply') {
          _setData(op, data);
        }
      }
    }
  }
})();
