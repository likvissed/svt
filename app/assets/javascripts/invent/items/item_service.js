(function() {
  'use strict';

  app.service('InventItem', InventItem);

  InventItem.$inject = ['TablePaginator', 'Config', 'Server', 'Error', 'InventItemFiltersFactory'];

  function InventItem(TablePaginator, Config, Server, Error, InventItemFiltersFactory) {
    this.Config = Config;
    this.Server = Server;
    this.Error = Error;
    this.TablePaginator = TablePaginator;
    this.Filters = InventItemFiltersFactory;
  }

  /**
   * Инициализация данных.
   */
  InventItem.prototype.init = function(init) {
    var self = this;

    if (angular.isUndefined(init)) {
      init = false;
    }

    return this.Server.Invent.Item.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this.Filters.getSelected()
      },
      function(response) {
        // Список всей техники
        self.items = response.data;
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);

        if (response.filters) {
          self.Filters.setPossibleValues(response.filters);
        }
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };
})();