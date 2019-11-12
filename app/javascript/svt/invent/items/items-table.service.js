import { app } from '../../app/app';

(function() {
  'use strict';

  app.service('InventItemsTable', InventItemsTable);

  InventItemsTable.$inject = ['TablePaginator', 'Config', 'Server', 'Error', 'InventItemsTableFiltersFactory'];

  function InventItemsTable(TablePaginator, Config, Server, Error, InventItemsTableFiltersFactory) {
    this.Config = Config;
    this.Server = Server;
    this.Error = Error;
    this.TablePaginator = TablePaginator;
    this.Filters = InventItemsTableFiltersFactory;
  }

  /**
   * Инициализация данных.
   */
  InventItemsTable.prototype.init = function(init = false) {
    return this.Server.Invent.Item.query(
      {
        start       : this.TablePaginator.startNum(),
        length      : this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters     : this.Filters.getFiltersToSend()
      },
      (response) => {
        // Список всей техники
        this.items = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (response.filters) {
          this.Filters.setPossibleValues(response.filters, true);
          this.Filters.setDefaultValues();
        }
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Загрузить комнаты выбранного корпуса.
   */
  InventItemsTable.prototype.loadRooms = function() {
    this.clearRooms();
    this.Server.Location.rooms(
      { building_id: this.Filters.getSelected().building.building_id },
      (data) => this.Filters.setPossibleValues({ rooms: data }),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Очистить список комнат.
   */
  InventItemsTable.prototype.clearRooms = function() {
    this.Filters.clearRooms();
  };
})();
