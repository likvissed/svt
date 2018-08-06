import { app } from '../../app/app';

(function () {
  'use strict';

  app.service('WorkplacesFilter', WorkplacesFilter);

  WorkplacesFilter.$inject = ['Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WorkplacesFilter(Server, Config, Flash, Error) {
    this.filters = {
      statuses: { '': 'Все статусы' },
      types: [{
        workplace_type_id: '',
        short_description: 'Все типы'
      }]
    };
    this.selectedTableFilters = {
      invent_num: '',
      workplace_id: '',
      workplace_type_id: this.filters.types[0].workplace_type_id,
      division: '',
      status: '',
      fullname: ''
    };
  }

  /**
   * Заполнить фильтры данными.
   */
  WorkplacesFilter.prototype.set = function(data) {
    this.filters.divisions = data.divisions;
    Object.assign(this.filters.statuses, data.statuses);
    this.filters.types = this.filters.types.concat(data.types);
  };

  /**
   * Получить выбранные фильтры.
   */
  WorkplacesFilter.prototype.get = function() {
    let obj = angular.copy(this.selectedTableFilters);
    obj.workplace_count_id = obj.division.workplace_count_id;
    delete(obj.division);

    return obj;
  };
})();