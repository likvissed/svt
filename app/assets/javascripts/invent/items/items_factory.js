(function () {
  'use strict';

  class InvItem {
    constructor(Config, Server, Error) {
      this._Config = Config;
      this._Server = Server;
      this._Error = Error;
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
     *
     * @param init - флаг, показывающий, нужно ли получить данные для фильтров (типы техники, виды свойств и т.д.)
     */
    init(init) {
      let
        start = (this.pagination.currentPage - 1) * this._Config.global.uibPaginationConfig.itemsPerPage,
        selected = this.filters.selected;

      return this._Server.Invent.Item.query(
        {
          start: start,
          length: this._Config.global.uibPaginationConfig.itemsPerPage,
          init_filters: init,
          filters: {
            item_id: selected.item_id,
            type_id: selected.inv_type.type_id,
            invent_num: selected.invent_num,
            responsible: selected.responsible,
            properties: (() => {
              let arr = [];

              selected.properties.forEach(function(el) { this.push(el.property_id); }, arr);

              return arr;
            })(),
            prop_values: selected.prop_values,
            exact_prop_values: selected.exact_prop_values
          }
        },
        (response) => {
          // Список всей техники
          this.items = response.data;
          // Данные для составления нумерации страниц
          this.pagination.filteredRecords = response.recordsFiltered;
          this.pagination.totalRecords = response.recordsTotal;
          this.pagination.init = true;

          if (response.filters) {
            // Данные для фильтра выбора типа техники
            this.filters.lists.invTypeFilters = this.filters.lists.invTypeFilters.concat(response.filters.inv_types);
            selected.inv_type = this.filters.lists.invTypeFilters[0];

            // Данные для фильтра выбора свойства и указания значения
            this.filters.lists.invPropertyFilters = this.filters.lists.invPropertyFilters.concat(response.filters.inv_properties);
            selected.properties[0] = this.filters.lists.invPropertyFilters[0];
            selected.prop_values[0] = '';
            selected.exact_prop_values[0] = false;
          }
        },
        (response, status) => { this._Error.response(response, status) }
      );
    }

    /**
     * Добавить фильтр
     */
    addPropFilter() {
      this.filters.selected.properties.push(angular.copy(this._filterTemplate));
      this.filters.selected.prop_values.push('');
      this.filters.selected.exact_prop_values.push(false);
    };

    /**
     * Удалить указанный фильтр
     */
    delPropFilter(index) {
      this.filters.selected.properties.splice(index, 1);
      this.filters.selected.prop_values.splice(index, 1);
      this.filters.selected.exact_prop_values.splice(index, 1);
    }
  }

  app.service('InvItem', InvItem);

  InvItem.$inject = ['Config', 'Server', 'Error'];
})();