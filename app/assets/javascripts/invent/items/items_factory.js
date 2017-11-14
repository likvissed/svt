(function () {
  'use strict';

  app.service('InvItem', InvItem);

  InvItem.$inject = ['Config', 'Server', 'Error'];

  function InvItem(Config, Server, Error) {
    this.Config = Config;
    this.Server = Server;
    this.Error = Error;

    this._filterTemplate = {
      property_id: 0,
      long_description: 'Выберите свойство'
    };

    this.pagination = {
      init: false,
      filteredRecords: 0,
      totalRecords: 0,
      currentPage: 1,
      maxSize: 5
    };
    this.filters = {
      // Фильтры установленные пользователем
      selected: {
        item_id: '',
        inv_type: { type_id: 0 },
        invent_num: '',
        responsible: '',
        properties: [],
        prop_values: [],
        exact_prop_values: []
      },
      // Варианты выбора фильтров
      lists: {
        invTypeFilters: [
          {
            type_id: 0,
            short_description: 'Все типы'
          }
        ],
        invPropertyFilters: [angular.copy(this._filterTemplate)]
      }
    };
  }

  /**
   * Инициализация данных.
   */
  InvItem.prototype.init = function (init) {
    var
      self = this,
      start = (this.pagination.currentPage - 1) * this.Config.global.uibPaginationConfig.itemsPerPage,
      selected = this.filters.selected;

    if (angular.isUndefined(init)) {
      init = false;
    }

    self.pagination.init = false;

    return this.Server.Invent.Item.query(
      {
        start: start,
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: {
          item_id: selected.item_id,
          type_id: selected.inv_type.type_id,
          invent_num: selected.invent_num,
          responsible: selected.responsible,
          properties: (function () {
            var arr = [];

            selected.properties.forEach(function (el) { this.push(el.property_id); }, arr);

            return arr;
          })(),
          prop_values: selected.prop_values,
          exact_prop_values: selected.exact_prop_values
        }
      },
      function (response) {
        // Список всей техники
        self.items = response.data;
        // Данные для составления нумерации страниц
        self.pagination.filteredRecords = response.recordsFiltered;
        self.pagination.totalRecords = response.recordsTotal;
        self.pagination.init = true;

        if (response.filters) {
          // Данные для фильтра выбора типа техники
          self.filters.lists.invTypeFilters = self.filters.lists.invTypeFilters.concat(response.filters.inv_types);
          selected.inv_type = self.filters.lists.invTypeFilters[0];

          // Данные для фильтра выбора свойства и указания значения
          self.filters.lists.invPropertyFilters = self.filters.lists.invPropertyFilters.concat(response.filters.inv_properties);
          selected.properties[0] = self.filters.lists.invPropertyFilters[0];
          selected.prop_values[0] = '';
          selected.exact_prop_values[0] = false;
        }
      },
      function (response, status) {
        self.Error.response(response, status);
      });
  };

  /**
   * Добавить фильтр
   */
  InvItem.prototype.addPropFilter = function () {
    this.filters.selected.properties.push(angular.copy(this._filterTemplate));
    this.filters.selected.prop_values.push('');
    this.filters.selected.exact_prop_values.push(false);
  };

  /**
   * Удалить указанный фильтр
   */
  InvItem.prototype.delPropFilter = function (index) {
    this.filters.selected.properties.splice(index, 1);
    this.filters.selected.prop_values.splice(index, 1);
    this.filters.selected.exact_prop_values.splice(index, 1);
  }
})();