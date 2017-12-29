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
  }

  Order.prototype._processingData = function(data) {
    this._setOrder(data.order);
    // Заполнить список отделов
    this.additional.divisions = data.divisions;
    // Заполнить список типов оборудования
    this.additional.eqTypes = data.eq_types;
    // Заполнить список работников отдела
    this.additional.users = data.users || [];
  };

  /**
   * Создать объект Order
   */
  Order.prototype._setOrder = function(order) {
    this.order = order;
    if (!this.order.operations_attributes) {
      this.order.operations_attributes = [];
    }
    this.additional.visibleCount = this.order.operations_attributes.length;
  };

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

  Order.prototype.loadOrder = function(order_id) {
    var self = this;

    return this.Server.Warehouse.Order.edit(
      { warehouse_order_id: order_id },
      function (data) {
        self._processingData(data);
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
  Order.prototype.init = function(type) {
    var self = this;

    return this.Server.Warehouse.Order.newOrder(
      { operation: type },
      function(data) {
        self._processingData(data);
        self.Operation.setTemplate(data.operation);
      },
      function(response, status) {
        self.Error.response(response, status);
      }).$promise;
  };

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
   * @param type
   * @param item
   */
  Order.prototype.addPosition = function(type, item) {
    this.order.operations_attributes.push(this.Operation.generate(type, item));
    this.additional.visibleCount ++;
  };

  /**
   * Удалить объект operation из ордера
   *
   * @param item
   */
  Order.prototype.delPosition = function(item) {
    console.log(item);
    if (item.id) {
      item._destroy = 1;
    } else {
      var index = this.order.operations_attributes.indexOf(item);
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
    obj.operations_attributes.forEach(function(el) { delete(el.inv_item); });

    if (obj.consumer && obj.consumer.match(/^\d+$/)) {
      obj.creator_id_tn = obj.consumer;
    } else {
      obj.creator_fio = obj.consumer;
    }

    delete(obj.consumer);

    return obj;
  }
})();

