(function () {
  'use strict';

  app.service('Workplaces', Workplaces);

  Workplaces.$inject = ['Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Workplaces(Server, TablePaginator, Config, Flash, Error) {
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.filters = {
      statuses: { 'all': 'Все статусы' },
      types: [{
        workplace_type_id: 0,
        short_description: 'Все типы'
      }]
    };
    this.selectedTableFilters = {
      invent_num: '',
      workplace_id: '',
      workplace_type_id: this.filters.types[0].workplace_type_id,
      division: '',
      status: 'all',
      fullname: ''
    };
  }

  Workplaces.prototype._getFiltersToSend = function() {
    var obj = angular.copy(this.selectedTableFilters);
    obj.workplace_count_id = obj.division.workplace_count_id;
    delete(obj.division);

    return obj;
  };

  Workplaces.prototype.loadWorkplaces = function(init) {
    var self = this;

    return this.Server.Invent.Workplace.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this._getFiltersToSend()
      },
      function(response) {
        // Список РМ
        self.workplaces = response.data;
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);

        if (init) {
          self.filters.divisions = response.filters.divisions;
          Object.assign(self.filters.statuses, response.filters.statuses);
          self.filters.types = self.filters.types.concat(response.filters.types);
        }
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  };
})();