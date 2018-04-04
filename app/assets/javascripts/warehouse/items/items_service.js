(function () {
  'use strict';

  app.service('WarehouseItems', WarehouseItems);

  WarehouseItems.$inject = ['WarehouseOrder', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WarehouseItems(WarehouseOrder, Server, TablePaginator, Config, Flash, Error) {
    this.Order = WarehouseOrder;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.selectedTableFilters = {
      showOnlyPresence: true,
      used: 'all',
      item_type: ''
    };
    this.filters = {};
    this.filters.selUsedFilter = [
      {
        descr: 'Все состояния',
        value: 'all'
      },
      {
        descr: 'Б/У',
        value: 'true'
      },
      {
        descr: 'Новое',
        value: 'false'
      }
    ];
  }

  WarehouseItems.prototype.loadItems = function(init) {
    var self = this;

    return this.Server.Warehouse.Item.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this.selectedTableFilters,
        selected_order_id: self.Order.order.id
      },
      function(response) {
        // Список элементов склада
        self.items = response.data;
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);

        if (init) {
          // Данные для фильтров
          self.filters.selItemTypesFiler = response.filters.item_types;
        }
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };

  WarehouseItems.prototype.findSelected = function() {
    var self = this;

    if (self.Order.order.operations_attributes.length == 0) {
      this.items.map(function(item) { item.added_to_order = false; })
      return;
    }

    this.items.forEach(function(item) {
      if (self.Order.order.operations_attributes.find((function (op) { return op.item_id == item.id }))) {
        item.added_to_order = true;
      } else {
        item.added_to_order = false;
      }
    });
  }
})();