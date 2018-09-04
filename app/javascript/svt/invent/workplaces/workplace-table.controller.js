import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('WorkplaceTableCtrl', WorkplaceTableCtrl);

  WorkplaceTableCtrl.$inject = ['$scope', 'Workplaces', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];

  /**
   * Управление таблицей рабочих мест.
   */
  function WorkplaceTableCtrl($scope, Workplaces, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.Workplaces = Workplaces;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.pagination = TablePaginator.config();
    this.sort = Workplaces.sorting;

    this._loadWorkplaces(true);
    this._initActionCable();

    $scope.$on('WorkplaceTableCtrl::reloadWorkplacesTable', () => this.reloadWorkplaces());
  };

  /**
   * Загрузить данные о РМ.
   *
   * @param init
   */
  WorkplaceTableCtrl.prototype._loadWorkplaces = function(init) {
    this.Workplaces.loadWorkplaces(init).then(
      (response) => this.workplaces = this.Workplaces.workplaces
    );
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  WorkplaceTableCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::WorkplacesChannel');

    consumer.subscribe(() => this._loadWorkplaces());
  };

  /**
   * Загрузить список РМ.
   */
  WorkplaceTableCtrl.prototype.reloadWorkplaces = function() {
    this._loadWorkplaces();
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceTableCtrl.prototype.destroyWp = function(id) {
    let confirm_str = "Вы действительно хотите удалить рабочее место \"" + id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Workplace.delete(
      { workplace_id: id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };
})();