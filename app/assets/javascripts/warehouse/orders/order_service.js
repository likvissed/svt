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
    this._orderTemplate = {};

    this.additional = {};
  }

  Order.prototype._processingData = function(data) {
    this._setOrder(data.order);
    // Заполнить список отделов
    this.additional.divisions = data.divisions;
    // Заполнить список типов оборудования
    this.additional.eqTypes = data.eq_types;

    this.Operation.setTemplate(data.operation, this.order.operation);
  }

  /**
   * Создать объект Order
   */
  Order.prototype._setOrder = function(order) {
    this.order = order;
    if (!this.order.operations_attributes) {
      this.order.operations_attributes = [];
    }
    this._orderTemplate = angular.copy(this.order);
    this.additional.visibleCount = this.order.operations_attributes.length;
  };

  /**
   * Установить связь объектов массива operations_attributes и inv_items_attributes
   */
  Order.prototype._associateSelectedOperations = function() {
    var
      self = this,
      operation,
      index;

    this.order.selected_op.forEach(function(sel_op) {
      operation = self.order.operations_attributes.find(function(op) { return op.id == sel_op.warehouse_operation_id; });
      index = self.order.inv_items_attributes.findIndex(function(inv_item) { return inv_item.id == sel_op.invent_item_id; });
      if (index != -1) {
        operation.inv_item_index = index;
        operation.invent_item_id = self.order.inv_items_attributes[index].id;
      }
    });
  }

  /**
   * Загрузить список ордеров
   */
  Order.prototype.loadOrders = function() {
    var self = this;

    return this.Server.Warehouse.Order.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
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
  Order.prototype.loadOrder = function(order_id) {
    var self = this;

    return this.Server.Warehouse.Order.edit(
      { warehouse_order_id: order_id },
      function (data) {
        self._processingData(data);
        console.log(self.order);
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
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

    obj.operations_attributes.forEach(function(el) {
      delete(el.item);
      delete(el.inv_item);
      delete(el.inv_item_index);
      delete(el.formatted_date);
    });

    if (obj.inv_items_attributes) {
      obj.inv_items_attributes.forEach(function(el) {
        delete(el.property_values);
        delete(el.model);
       });
    }

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
      { warehouse_order_id: this.order.warehouse_order_id },
      { order: sendData },
      function (response) {
        angular.extend(self.order, response);
        self._associateSelectedOperations();
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  /**
   * Удалить установленные ассоциации из массива operations_attributes
   */
  Order.prototype.clearAssociations = function() {
    this.order.operations_attributes.forEach(function(op) { delete op.inv_item_index; });

    delete(this.order.inv_items_attributes);
  };

  /**
   * Обновить данные о технике, связанной с операцией текущего ордера
   *
   * @param op - операция
   * @param data - новые данные
   */
  Order.prototype.refreshInvItemData = function(op, data) {
    var refreshItem = this.order.inv_items_attributes.find(function(item) {
      return item.id == op.invent_item_id;
    })

    angular.extend(refreshItem, data);
  }
})();

