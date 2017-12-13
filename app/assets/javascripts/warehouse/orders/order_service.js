(function () {
  'use strict';

  app.service('Order', Order);

  Order.$inject = ['Operation', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Order(Operation, Server, TablePaginator, Config, Flash, Error) {
    this.Operation = Operation;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
  }

  /**
   * Создать объект Order
   */
  Order.prototype._setOrder = function(data) {
    this.order = data;
    this.order.item_to_orders_attributes = [];
  }

  Order.prototype.loadOrders = function() {
    var self = this;

    return this.Server.Warehouse.Order.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      function(response) {
        // Список всех ордеров
        self.orders = response.data
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);
      },
      function(response, status) {
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
        // Создать объект Order
        self._setOrder(data.order);
        // Заполнить список отделов
        self.divisions = data.divisions;
        // Заполнить список типов оборудования
        self.eqTypes = data.eq_types;
      },
      function(response, status) {
        self.Error.response(response, status);
      }).$promise;
  };

  Order.prototype.loadUsers = function() {
    var self = this;

    return this.Server.UserIss.usersFromDivision(
      { division: self.order.consumer_dept },
      function(data) {
        self.users = data;
      },
      function(response, status) {
        self.Error.response(response, status);
      }).$promise;
  };

  /**
   * Добавить данные по ответственному к объекту order.
   */
  Order.prototype.setConsumer = function(consumer) {
    this.order.consumer_id_tn = consumer.id_tn;
    this.order.consumer_fio = consumer.fio;
  }

  /**
   * Добавить объект item к текущему ордеру
   *
   * @param item
   */
  Order.prototype.addItem = function(item) {
    this.order.item_to_orders_attributes.push({ invent_item_id: item.item_id, item: item });
  }

  /**
   * Удалить объект item из ордера
   *
   * @param item
   */
  Order.prototype.delItem = function(item) {
    if (item.id) {
      item._destroy = 1;
    } else {
      var index = this.order.item_to_orders_attributes.indexOf(item);
      this.order.item_to_orders_attributes.splice(index, 1);
    }
  }

  /**
   * Загрузить Б/У технику указанного типа.
   *
   * @param type_id - тип загружаемой техники
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
  }
})();

