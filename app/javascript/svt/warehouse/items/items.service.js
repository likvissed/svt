import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .service('WarehouseItems', WarehouseItems);

  WarehouseItems.$inject = ['WarehouseOrder', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error', '$uibModal'];

  function WarehouseItems(WarehouseOrder, Server, TablePaginator, Config, Flash, Error, $uibModal) {
    this.Order = WarehouseOrder;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.$uibModal = $uibModal;

    this.selectedTableFilters = {
      show_only_presence: true,
      status            : '',
      item_type         : '',
      barcode           : '',
      invent_num        : '',
      invent_item_id    : ''
    };
    this.filters = {
      selStatusFilter: { '': 'Все состояния' }
    };
  }

  WarehouseItems.prototype.loadItems = function(init) {
    return this.Server.Warehouse.Item.query(
      {
        start            : this.TablePaginator.startNum(),
        length           : this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters     : init,
        filters          : this.selectedTableFilters,
        selected_order_id: this.Order.order.id
      },
      (response) => {
        // Список элементов склада
        this.items = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          // Данные для фильтров
          this.filters.selItemTypesFiler = response.filters.item_types;
          this.filters.selStatusFilter = Object.assign(this.filters.selStatusFilter, response.filters.statuses);
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

  /**
   * Открытие формы редактирования расположения техники
   */
  WarehouseItems.prototype.openEditLocationItem = function(item) {
    let size_modal = 'md';

    if (item.count > 1 && item.status == 'non_used') { size_modal = 'lg' }
    this.$uibModal.open({
      templateUrl : 'WarehouseEditLocationItemCtrl.slim',
      controller  : 'WarehouseEditLocationCtrl',
      controllerAs: 'edit',
      backdrop    : 'static',
      size        : size_modal,
      resolve     : {
        items: function() {
          return { item: item };
        }
      }
    });
  };

  /**
   * Проверка на заполненное расположение техники
   */
  WarehouseItems.prototype.completedLocation = function(location) {
    if (!location) { return false }

    if (!location.name) {
      // Присвоить пустое значение в name, если его не существует, чтобы сравнить с .length
      location.name = '';
    }

    if (location.room_id !== null && location.room_id !== -1) {
      return true;
    } else if (location.room_id == -1 && location.name.length != 0) {
      // если задан ввод комнаты вручную
      return true;
    }

    return false;
  }

})();
