import { app } from '../../app/app';

(function () {
  'use strict';

  app.factory('OrderFilters', OrderFilters);

  function OrderFilters() {
    let
      filters = {
        operations: { '': 'Все типы' }
      },
      selected = {
        id                       : '',
        invent_workplace_id      : '',
        invent_num               : '',
        barcode                  : '',
        division                 : '',
        operation                : '',
        creator_fio              : '',
        consumer_fio             : '',
        show_only_with_attachment: '',
        item_type                : ''
      };

    return {
      set: (data) => {
        filters.divisions = data.divisions;
        filters.operations = Object.assign(filters.operations, data.operations);
        filters.item_types = data.item_types;
      },
      getFilters      : () => filters,
      getSelected     : () => selected,
      getFiltersToSend: () => {
        let obj = angular.copy(selected);

        obj.consumer_dept = obj.division.division;

        delete(obj.division);

        return obj;
      }
    }
  }
})();
