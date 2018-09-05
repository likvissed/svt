import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WarehouseSuppliesCtrl', WarehouseSuppliesCtrl);

  WarehouseSuppliesCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'Config', 'WarehouseSupply', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

  function WarehouseSuppliesCtrl($uibModal, TablePaginator, ActionCableChannel, Config, WarehouseSupply, WarehouseOrder, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Supply = WarehouseSupply;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    this._loadSupplies();
    this._initActionCable();
  };

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  WarehouseSuppliesCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Warehouse::SuppliesChannel');

    consumer.subscribe(() => this._loadSupplies());
  }

  WarehouseSuppliesCtrl.prototype._loadSupplies = function() {
    this.Server.Warehouse.Supply.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      (response) => {
        // Список всех ордеров
        this.supplies = response.data || [];
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);
      },
      (response, status) => this.Error.response(response, status)
    );
  }

  WarehouseSuppliesCtrl.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'editSupplyModal.slim',
      controller: 'EditSupplyCtrl',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  }

  /**
   * Открыть форму создания поставки
   */
  WarehouseSuppliesCtrl.prototype.newSupply = function() {
    this.Server.Warehouse.Supply.newSupply({},
      (data) => {
        this.Supply.init(data);
        this._openEditModal();
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Редактировать поставку
   *
   * @param supply
   */
  WarehouseSuppliesCtrl.prototype.editSupply = function(supply) {
    this.Server.Warehouse.Supply.edit(
      { id: supply.id },
      (data) => {
        this.Supply.init(data);
        this._openEditModal();
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Удалить поставку
   *
   * @param supply
   */
  WarehouseSuppliesCtrl.prototype.destroySupply = function(supply) {
    let confirm_str = "Вы действительно хотите удалить поставку \"" + supply.id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Supply.delete(
      { id: supply.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };
})();
