(function () {
  'use strict';

  app.service('WarehouseItems', WarehouseItems);

  WarehouseItems.$inject = ['Order', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WarehouseItems(Order, Server, TablePaginator, Config, Flash, Error) {
    this.Order = Order;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
  }

  WarehouseItems.prototype.loadItems = function() {
    var self = this;

    return this.Server.Warehouse.Item.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      function(response) {
        // Список элементов склада
        self.items = response.data;
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  WarehouseItems.prototype.findSelected = function() {
    var self = this;

    this.items.forEach(function(item) {
      if (self.Order.order.operations_attributes.find((function (op) { return op.item_id == item.id }))) {
        item.added_to_order = true;
      }
    });
  }
})();