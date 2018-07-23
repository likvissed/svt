(function () {
  'use strict';

  app.service('WarehouseOrder', WarehouseOrder);

  WarehouseOrder.$inject = ['WarehouseOperation', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WarehouseOrder(WarehouseOperation, Server, TablePaginator, Config, Flash, Error) {
    this.Operation = WarehouseOperation;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.additional = {};
    this.order = {};
  }

  WarehouseOrder.prototype._initVisibleCount = function(count) {
    this.additional.visibleCount = count || 0;
  }

  WarehouseOrder.prototype._processingData = function(data, onlyOrder) {
    this._setOrder(data.order);
    onlyOrder = onlyOrder || false;

    if (!onlyOrder) {
      // Заполнить список отделов
      this.additional.divisions = data.divisions;
      // Заполнить список типов оборудования
      this.additional.eqTypes = [{ type_id: 0, short_description: 'Выберите тип' }].concat(data.eq_types);

      this.Operation.setTemplate(data.operation, this.order.operation);
    }
  }

  /**
   * Создать объект Order
   */
  WarehouseOrder.prototype._setOrder = function(order) {
    angular.extend(this.order, order);
    this.order.operations_attributes = order.operations_attributes || [];
    this.order.consumer = order.consumer;

    if (typeof this._orderTemplate === 'undefined') {
      this._orderTemplate = angular.copy(this.order);
    }
    this._initVisibleCount(this.order.operations_attributes.length);
  };

  WarehouseOrder.prototype.getOperation = function(item) {
    if (!this.order) { return false; }
    return this.order.operations_attributes.find(function(op) { return op.item_id == item.id; })
  }

  /**
   * Загрузить список ордеров
   *
   * @params operation
   */
  WarehouseOrder.prototype.loadOrders = function(operation) {
    var self = this;

    return this.Server.Warehouse.Order.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        operation: operation
      },
      function(response) {
        // Список всех ордеров
        self.orders = response.data;
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  /**
   * Загрузить данные указанного ордера
   */
  WarehouseOrder.prototype.loadOrder = function(order_id, onlyOrder, checkUnreg) {
    var self = this;
    onlyOrder = onlyOrder || false;

    return this.Server.Warehouse.Order.edit(
      {
        id: order_id,
        check_unreg: checkUnreg
      },
      function (data) {
        self._processingData(data, onlyOrder);
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  /**
   * Загрузить данные о текущем ордере заново
   */
  WarehouseOrder.prototype.reloadOrder = function() {
    this.loadOrder(this.order.id, true);
  };

  /**
   * Загрузить данные с сервера: объект ордер, список отделов
   *
   * @param type - тип ордера (на приход или расход)
   */
  WarehouseOrder.prototype.init = function(type, data) {
    var self = this;

    if (data) {
      self._processingData(data);

      return true;
    }

    return this.Server.Warehouse.Order.newOrder(
      { operation: type },
      function(data) {
        self._processingData(data);
      },
      function(response, status) {
        self.Error.response(response, status);
      }).$promise;
  };

  /**
   * Заново заполнить объект order начальными данными.
   */
  WarehouseOrder.prototype.reinit = function() {
    angular.extend(this.order, angular.copy(this._orderTemplate));
    this._initVisibleCount();
  }

  // Order.prototype.loadUsers = function() {
  //   var self = this;
  //
  //   return this.Server.UserIss.usersFromDivision(
  //     { division: self.order.consumer_dept },
  //     function(data) {
  //       self.additional.users = data;
  //     },
  //     function(response, status) {
  //       self.Error.response(response, status);
  //     }).$promise;
  // };

  WarehouseOrder.prototype.prepareToExec = function() {
    this.order.operations_attributes.forEach(function(op) { op.status = 'done'; });
  };

  /**
   * Добавить данные по ответственному к объекту order.
   */
  WarehouseOrder.prototype._setConsumer = function() {
    this.order.consumer_id_tn = angular.copy(this.order.consumer.id_tn) || null;
    this.order.consumer_fio = angular.copy(this.order.consumer.fio) || null;
    this.order.consumer_tn = angular.copy(this.order.consumer.tn) || null;
  };

  /**
   * Добавить объект operation к текущему ордеру
   *
   * @param warehouseType
   * @param item
   */
  WarehouseOrder.prototype.addPosition = function(warehouseType, item) {
    this.order.operations_attributes.push(this.Operation.generate(warehouseType, item));
    this.additional.visibleCount ++;
  };
  /**

   * Удалить объект operation из ордера
   *
   * @param operation
   */
  WarehouseOrder.prototype.delPosition = function(operation) {
    if (operation.id) {
      operation._destroy = 1;
    } else {
      var index = this.order.operations_attributes.indexOf(operation);
      this.order.operations_attributes.splice(index, 1);
    }

    this.additional.visibleCount --;
  };

  /**
   * Подготовить данные для отправки на сервер.
   */
  WarehouseOrder.prototype.getObjectToSend = function() {
    this._setConsumer();

    var obj = angular.copy(this.order);

    obj.operations_attributes.forEach(function(op) {
      delete(op.item);
      delete(op.inv_items);
      delete(op.formatted_date);
      delete(op.inv_item_to_operations);

      if (op.inv_items_attributes) {
        op.inv_items_attributes.forEach(function(inv_item) {
          Object.keys(inv_item).forEach(function(key) {
            if (['id', 'invent_num', 'serial_num'].includes(key)) { return true; }

            delete(inv_item[key])
          });
        });
      }
    });

    delete(obj.consumer);
    delete(obj.selected_op);

    return obj;
  }

  /**
   * Проверить корректность данных ордера перед выдачей оборудования
   */
  WarehouseOrder.prototype.prepareToDeliver = function() {
    var
      self = this,
      sendData = this.getObjectToSend();

    return this.Server.Warehouse.Order.prepareToDeliver(
      { id: this.order.id },
      { order: sendData },
      function (response) {
        var newOp;

        self.order.operations_attributes.forEach(function(op) {
          newOp = response.operations_attributes.find(function(el) { return op.id == el.id })
          angular.extend(op, newOp);
        });
        self.order.selected_op = response.selected_op;
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };
})();

