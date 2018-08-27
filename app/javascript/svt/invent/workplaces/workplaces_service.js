import { app } from '../../app/app';

(function () {
  'use strict';

  app.service('Workplaces', Workplaces);

  Workplaces.$inject = ['WorkplacesFilter', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Workplaces(Filter, Server, TablePaginator, Config, Flash, Error) {
    this.Filter = Filter;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.sorting = {
      name: 'workplace_id',
      type: 'desc'
    };
  }

  Workplaces.prototype.loadWorkplaces = function(init) {
    return this.Server.Invent.Workplace.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this.Filter.get(),
        sort: this.sorting
      },
      (response) => {
        // Список РМ
        this.workplaces = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          this.Filter.set(response.filters);
        }
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  Workplaces.prototype.loadListWorkplaces = function() {
    return this.Server.Invent.Workplace.list(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        filters: this.Filter.get()
      },
      (response) => {
        // Список РМ
        this.workplaces = response.data;
        this._prepareWorkplaceToRender();

        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    ).$promise;
  };

  Workplaces.prototype._prepareWorkplaceToRender = function() {
    let
      items,
      composition;

    this.workplaces.forEach((el) => {
      items = [];

      el.items.forEach(function(value) { items.push('<li>' + value + '</li>'); });
      el.renderData = '<span>' + el.workplace + '</span><br>';
      composition = items.length == 0 ? 'Состав отсутствует' : 'Состав:<ul>' + items.join('') + '</ul>';
      el.renderData += composition;
    });
  }
})();