import { app } from '../app/app';

(function () {
  'use strict';

  app.service('User', User);

  User.$inject = ['Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function User(Server, TablePaginator, Config, Flash, Error) {
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.toSelect = {
      role: {
        id: null,
        short_description: 'Выберите роль'
      }
    };
  }

  User.prototype._initRoles = function(data) {
    this.roles = [];
    this.roles = this.roles.concat(data.roles);
  };

  User.prototype._initUser = function(data) {
    this.user = data.user;
    this.user.role = this.user.role_id ? data.roles.find((el) => el.id == this.user.role_id) : this.toSelect.role;
  };

  /**
   * Инициализировать объект user.
   */
  User.prototype.initData = function(data) {
    this._initRoles(data);
    this._initUser(data);
  };
})();