import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('OrdersController', OrdersController);

  OrdersController.$inject = ['$uibModal', '$scope', 'ActionCableChannel', 'TablePaginator', 'WarehouseOrder', 'OrderFilters', 'Flash', 'Error', 'Server'];

  function OrdersController($uibModal, $scope, ActionCableChannel, TablePaginator, WarehouseOrder, OrderFilters, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Order = WarehouseOrder;
    this.Filters = OrderFilters;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    this.filters = this.Filters.getFilters();
    this.selected= this.Filters.getSelected();

    $scope.initOperation = (operation) => {
      this.operation = operation;

      this._loadOrders(true);
      this._initActionCable();
    };
  }

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  OrdersController.prototype._initActionCable = function() {
    let channelType;

    if (this.operation == 'in') {
      channelType = 'In';
    } else if (this.operation == 'out') {
      channelType = 'Out';
    } else if (this.operation == 'write_off') {
      channelType = 'WriteOff';
    }

    let consumer = new this.ActionCableChannel('Warehouse::' + channelType + 'OrdersChannel');
    consumer.subscribe(() => this._loadOrders());
  };

  /**
   * Загрузить список ордеров.
   */
  OrdersController.prototype._loadOrders = function(init) {
    this.Order.loadOrders(this.operation, init).then(() => this.orders = this.Order.orders);
  };

  /**
   * Открыть модальное окно
   *
   * @param operation
   */
  OrdersController.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'editInOrderModal.slim',
      controller: 'EditInOrderController',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  };

  /**
   * События изменения страницы.
   */
  OrdersController.prototype.reloadOrders = function() {
    this._loadOrders();
  };

  /**
   * Открыть окно создания ордера.
   */
  OrdersController.prototype.newOrder = function() {
    this.Order.init('in').then(() => this._openEditModal());
  };

  /**
   * Загрузить ордер для редактирования.
   *
   * @param order
   */
  OrdersController.prototype.editOrder = function(order) {
    this.Order.loadOrder(order.id).then(() => this._openEditModal());
  };

  /**
   * Открыть модальное окно для исполнения ордера.
   */
  OrdersController.prototype.execOrder = function(order) {
    let checkUnreg = order.operation == 'in';

    this.Order.loadOrder(order.id, false, checkUnreg).then(() => {
      this.$uibModal.open({
        templateUrl: 'execOrder.slim',
        controller: 'ExecOrderController',
        controllerAs: 'exec',
        size: 'lg',
        backdrop: 'static'
      });
    });
  };

  /**
   * Удалить ордер.
   *
   * @param order
   */
  OrdersController.prototype.destroyOrder = function(order) {
    let confirm_str = "Вы действительно хотите удалить ордер \"" + order.id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Order.delete(
      { id: order.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };
})();
