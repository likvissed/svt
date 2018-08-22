import { app } from '../../app/app';

(function () {
  'use strict';

  app.factory('OrderFilters', OrderFilters);

  function OrderFilters(Server, Error) {
    let
      filters = {
        operations: { '': 'Все типы' }
      },
      selected = {
        division: '',
        operation: '',
        creator_fio: '',
        consumer_fio: ''
      };

    return {
      set: (data) => {
        filters.divisions = data.divisions;
        filters.operations = Object.assign(filters.operations, data.operations);
      },
      getFilters: () => filters,
      getSelected: () => selected,
      getFiltersToSend: () => {
        let obj = angular.copy(selected);

        obj.consumer_dept = obj.division.division;

        delete(obj.division);

        return obj;
      }
    }
  }
})();