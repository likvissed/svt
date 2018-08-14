import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .service('WarehouseItems', WarehouseItems);

  WarehouseItems.$inject = ['WarehouseOrder', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WarehouseItems(WarehouseOrder, Server, TablePaginator, Config, Flash, Error) {
    this.Order = WarehouseOrder;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.selectedTableFilters = {
      show_only_presence: true,
      used: '',
      item_type: '',
      barcode: '',
      invent_num: '',
      invent_item_id: ''
    };
    this.filters = {};
    this.filters.selUsedFilter = [
      {
        descr: 'Все состояния',
        value: ''
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
    return this.Server.Warehouse.Item.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this.selectedTableFilters,
        selected_order_id: this.Order.order.id,
      },
      (response) => {
        // Список элементов склада
        this.items = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          // Данные для фильтров
          this.filters.selItemTypesFiler = response.filters.item_types;
        }
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  WarehouseItems.prototype.findSelected = function() {
    if (this.Order.order.operations_attributes.length == 0) {
      this.items.map((item) => item.added_to_order = false)
      return;
    }

    this.items.forEach((item) => {
      if (this.Order.order.operations_attributes.find((op) => op.item_id == item.id)) {
        item.added_to_order = true;
      } else {
        item.added_to_order = false;
      }
    });
  }
})();