(function () {
  'use strict';

  app
    .factory('Server', Server)
    .factory('TableSettings', TableSettings);

  Server.$inject  = ['$resource'];
  TableSettings.$inject   = [];

  /**
   * Фабрика для работы с CRUD действиями
   *
   * @class Inv.Server
   * @param $resource
   */
  function Server($resource) {
    return {
      /**
       * Ресурс модели рабочих мест
       *
       * @memberOf Inv.Server
       */
      Workplace: $resource('/workplaces/:id.json', {}, { update: { method: 'PATCH' } })
    }
  }

  /**
   * Фабрика для работы с таблицами.
   *
   * @class Inv.MainTable
   */
  function TableSettings() {

    function classTable(tableName) {
      this._index = 0;
    }

    classTable.prototype.renderIndex = function () {
      
    };

    return classTable;
  }

})();
