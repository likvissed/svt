import { app } from '../app/app';
import { FormValidationController } from '../app/app_controller';

(function() {
  'use strict';

  app
    .controller('UsersCtrl', UsersCtrl)
    .controller('EditUserCtrl', EditUserCtrl);

  UsersCtrl.$inject = ['$uibModal', 'User', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error'];
  EditUserCtrl.$inject = ['$uibModalInstance', 'User', 'Server', 'Flash', 'Error'];

  function UsersCtrl($uibModal, User, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.$uibModal = $uibModal;
    this.User = User;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.selectedTableFilters = {};

    this.pagination = TablePaginator.config();
    this._loadUsers(true);
    this._initActionCable();
  };

  UsersCtrl.prototype._getFiltersToSend = function() {
    let obj = angular.copy(this.selectedTableFilters);

    if (obj.role) {
      obj.role_id = obj.role.id;
      delete(obj.role);
    }

    return obj;
  };

  /**
   * Инициировать подключение к каналу UsersChannel
   */
  UsersCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('UsersChannel');

    consumer.subscribe(() => this._loadUsers());

    // this.$rootScope.$on('ModelsCtrl::UpdateTableFilters', function(event, vendors) {
    //   self.filters.vendors = vendors;
    //   self._checkCurrentVendorFilter();
    // });
  };

  /**
   * Загрузить список пользователей.
   *
   * @param init - определяет, нужно ли загружать данные для инициализации фильтров
   */
  UsersCtrl.prototype._loadUsers = function(init) {
    this.Server.User.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this._getFiltersToSend()
      },
      (response) => {
        this.users = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          this.filters = response.filters;
        }
      },
      (response, status) => this.Error.response(response, status)
    )
  };

  /**
   * Открыть модальное окно для создания/редактирования пользователей.
   */
  UsersCtrl.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'editUserModal.slim',
      controller: 'EditUserCtrl',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  };

  /**
   * Открыть форму создания пользователя.
   */
  UsersCtrl.prototype.newUser = function() {
    this.Server.User.newUser(
      (response) => {
        this.User.initData(response);
        this._openEditModal();
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Загрузить список пользователей заново.
   */
  UsersCtrl.prototype.reloadUsers = function() {
    this._loadUsers();
  };

  /**
   * Загрузить данные пользователя.
   *
   * @param user
   */
  UsersCtrl.prototype.editUser = function(user) {
    this.Server.User.edit(
      { id: user.id },
      (response) => {
        this.User.initData(response);
        this._openEditModal();
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Удалить пользователя.
   *
   * @param user
   */
  UsersCtrl.prototype.destroyUser = function(user) {
    let confirm_str = "Вы действительно хотите удалить пользователя \"" + user.fullname + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.User.delete(
      { id: user.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

  // =====================================================================================================================

  function EditUserCtrl($uibModalInstance, User, Server, Flash, Error) {
    this.setFormName('user');

    this.$uibModalInstance = $uibModalInstance;
    this.User = User;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;

    this.user = User.user;
    this.roles = User.roles;
    this.roles.unshift(this.User.toSelect.role);
  }

  // Унаследовать методы класса FormValidationController
  EditUserCtrl.prototype = Object.create(FormValidationController.prototype);
  EditUserCtrl.prototype.constructor = EditUserCtrl;

  EditUserCtrl.prototype.setRole = function(role) {
    this.user.role_id = this.user.role.id;
  };

  /**
   * Создать модель.
   */
  EditUserCtrl.prototype.ok = function() {
    if (this.user.id) {
      this.Server.User.update(
        { id: this.user.id },
        { user: this.user },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    } else {
      this.Server.User.save(
        { user: this.user },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      );
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditUserCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();