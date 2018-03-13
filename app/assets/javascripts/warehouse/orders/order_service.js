(function () {
  'use strict';

  app.service('Order', Order);

  Order.$inject = ['WarehouseOperation', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Order(WarehouseOperation, Server, TablePaginator, Config, Flash, Error) {
    this.Operation = WarehouseOperation;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.additional = {};
    this.order = {};
  }

  Order.prototype._initVisibleCount = function(count) {
    this.additional.visibleCount = count || 0;
  }

  Order.prototype._processingData = function(data, onlyOrder = false) {
    this._setOrder(data.order);

    if (!onlyOrder) {
      // Заполнить список отделов
      this.additional.divisions = data.divisions;
      // Заполнить список типов оборудования
      this.additional.eqTypes = data.eq_types;

      this.Operation.setTemplate(data.operation, this.order.operation);
    }
  }

  /**
   * Создать объект Order
   */
  Order.prototype._setOrder = function(order) {
    angular.extend(this.order, order);
    this.order.operations_attributes = order.operations_attributes || [];
    this.order.consumer = order.consumer;

    if (typeof this._orderTemplate === 'undefined') {
      this._orderTemplate = angular.copy(this.order);
    }
    this._initVisibleCount(this.order.operations_attributes.length);
  };

  /**
   * Загрузить список ордеров
   *
   * @params operation
   */
  Order.prototype.loadOrders = function(operation) {
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
  Order.prototype.loadOrder = function(order_id, onlyOrder = false) {
    var self = this;

    return this.Server.Warehouse.Order.edit(
      { id: order_id },
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
  Order.prototype.reloadOrder = function() {
    this.loadOrder(this.order.id, true);
  };

  /**
   * Загрузить данные с сервера: объект ордер, список отделов
   *
   * @param type - тип ордера (на приход или расход)
   */
  Order.prototype.init = function(type, data) {
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
  Order.prototype.reinit = function() {
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

  /**
   * Добавить данные по ответственному к объекту order.
   */
  Order.prototype.setConsumer = function(consumer) {
    if (!consumer) {
      consumer = {};
    }

    this.order.consumer_id_tn = consumer.id_tn || null;
    this.order.consumer_fio = consumer.fio || null;
  };

  /**
   * Добавить объект operation к текущему ордеру
   *
   * @param warehouseType
   * @param item
   */
  Order.prototype.addPosition = function(warehouseType, item) {
    this.order.operations_attributes.push(this.Operation.generate(warehouseType, item));
    this.additional.visibleCount ++;
  };
  /**

   * Удалить объект operation из ордера
   *
   * @param operation
   */
  Order.prototype.delPosition = function(operation) {
    if (operation.id) {
      operation._destroy = 1;
    } else {
      var index = this.order.operations_attributes.indexOf(operation);
      this.order.operations_attributes.splice(index, 1);
    }

    this.additional.visibleCount --;
  };

  /**
   * Загрузить Б/У технику указанного типа.
   *
   * @param type_id - тип загружаемой техники
   * @param invent_num
   */
  Order.prototype.loadBusyItems = function(type_id, invent_num) {
    var self = this;

    return this.Server.Invent.Item.busy(
      { type_id: type_id, invent_num: invent_num },
      function(response) {},
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  /**
   * Подготовить данные для отправки на сервер.
   */
  Order.prototype.getObjectToSend = function() {
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

    if (obj.consumer && obj.consumer.match(/^\d+$/)) {
      obj.consumer_tn = obj.consumer;
    } else {
      obj.consumer_fio = obj.consumer;
    }

    delete(obj.consumer);
    delete(obj.selected_op);

    return obj;
  }

  /**
   * Проверить корректность данных ордера перед выдачей оборудования
   */
  Order.prototype.prepareToDeliver = function() {
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

