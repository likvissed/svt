import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .service('InventItem', InventItem);

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
  InventItem.prototype.init = function(init = false) {
    return this.Server.Invent.Item.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this.Filters.getSelected()
      },
      (response) => {
        // Список всей техники
        this.items = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (response.filters) {
          this.Filters.setPossibleValues(response.filters);
        }
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Загрузить занятую Б/У технику указанного типа.
   *
   * @param type_id - тип загружаемой техники
   * @param invent_num - инвентарный номер
   * @param id
   * @param division - отдел
   */
  InventItem.prototype.loadBusyItems = function(type_id, invent_num, item_id, division) {
    return this.Server.Invent.Item.busy(
      {
        type_id: type_id,
        invent_num: invent_num,
        item_id: item_id,
        division: division
      },
      function(response) {},
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Загрузить доступную Б/У технику указанного типа.
   *
   * @param type_id - тип загружаемой техники
   */
  InventItem.prototype.loadAvaliableItems = function(type_id) {
    return this.Server.Invent.Item.avaliable(
      { type_id: type_id },
      function(response) {},
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };
})();