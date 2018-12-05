import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .controller('WarehouseItemsCtrl', WarehouseItemsCtrl);

  WarehouseItemsCtrl.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'WarehouseItems', 'WarehouseOrder', 'WarehouseSupply', 'Flash', 'Error', 'Server'];

  function WarehouseItemsCtrl($uibModal, ActionCableChannel, TablePaginator, WarehouseItems, WarehouseOrder, WarehouseSupply, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Items = WarehouseItems;
    this.Order = WarehouseOrder;
    this.Supply = WarehouseSupply;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();
    this.selectedFilters = this.Items.selectedTableFilters;
    this.filters = this.Items.filters;

    this._loadItems(true);
    this._initActionCable();
  }

  /**
   * Инициировать подключение к каналу ItemsChannel
   */
  WarehouseItemsCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Warehouse::ItemsChannel');

    consumer.subscribe((data) => {
      this.closeOrder();
      this._loadItems();
    });
  };

  /**
   * Загрузить список ордеров.
   */
  WarehouseItemsCtrl.prototype._loadItems = function(init) {
    this.Items.loadItems(init).then(
      (response) => {
        this.items = this.Items.items;
        this.orders = response.orders || [];

        if (init) {
          this.Order.init('out', response.order);
          this.order = this.Order.order;
          this.extraOrder = this.Order.additional;
        } else {
          this.Items.findSelected();
        }
      }
    );
  };

  /**
   * Открыть модальное окно для редактирования состава ордера.
   *
   * @param type
   */
  WarehouseItemsCtrl.prototype._openOrderModal = function(type) {
    let modalInstance = this.$uibModal.open({
      templateUrl: `edit${type}OrderModal.slim`,
      controller: `Edit${type}OrderController`,
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });

    modalInstance.result.then((result) => this.closeOrder());
  };

  /**
   * Открыть модальное окно для просмотра состава поставки.
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype._openSupplyModal = function(item) {
    this.$uibModal.open({
      templateUrl: 'showSupplyModal.slim',
      controller: 'ShowSupplyCtrl',
      controllerAs: 'show',
      size: 'md',
      backdrop: 'static',
      resolve: {
        data: { item: item }
      }
    });
  };

  /**
   * Показать данные о поставке.
   *
   * @param supply
   * @param item
   */
  WarehouseItemsCtrl.prototype.showSupply = function(supply, item) {
    this.Server.Warehouse.Supply.edit(
      { id: supply.id },
      (data) => {
        this.Supply.init(data);
        this._openSupplyModal(item);
      },
      (response, status) => this.Error.response(response, status)
    )
  };

  /**
   * Проверить, в наличии ли техника на складе.
   */
  WarehouseItemsCtrl.prototype.isItemInStock = function(item) {
    return item.count != 0 && item.count > item.count_reserved;
  }

  /**
   * Проверить, принадлежит ли техника выбранному ордеру.
   */
  WarehouseItemsCtrl.prototype.isItemInOrder = function(item) {
    if (!this.order) { return false; }
    return this.Order.getOperation(item);
  }

  WarehouseItemsCtrl.prototype.isItemInDoneOp = function(item) {
    let operation = this.isItemInOrder(item);

    if (!operation) { return false; }

    return operation.status == 'done'
  }

  /**
   * События изменения страницы.
   */
  WarehouseItemsCtrl.prototype.reloadItems = function() {
    this._loadItems();
  };

  /**
   * Показать/скрыть технику, у которой разница count-count_reserved=0
   */
  WarehouseItemsCtrl.prototype.showOnlyPresenceFilter = function() {
    this.selectedFilters.show_only_presence = !this.selectedFilters.show_only_presence;
    this.reloadItems();
  };

  /**
   * Добавить/удалить технику из ордера
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype.togglePosition = function(item) {
    if (item.added_to_order) {
      this.Order.addPosition(this.order.warehouse_type, angular.copy(item));
    } else {
      let operation = this.Order.getOperation(item);

      this.Order.delPosition(operation);
    }
  };

  /**
   * Открыть окно создания ордера.
   *
   * @param operation
   */
  WarehouseItemsCtrl.prototype.newOrder = function(operation) {
    let operationName;

    this.Order.init(operation).then(
      () => {
        operationName = operation == 'out' ? 'Out' : 'WriteOff'
        this._openOrderModal(operationName);
      }
    );
  };

  /**
   * Удалить технику со склада
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype.destroyItem = function(item) {
    let confirm_str = "Вы действительно хотите удалить \"" + item.item_type + "\" со склада?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Item.delete(
      { id: item.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Загрузить ордера для редактирования
   *
   * @param order
   */
  WarehouseItemsCtrl.prototype.loadOrder = function() {
    this.Order.loadOrder(this.selectedOrder.id, true).then(() => {
      this._openOrderModal('Out');
      this.Items.findSelected();

      this.reloadItems();
    });
  }

  /**
   * Очистить выбранный ордер
   */
  WarehouseItemsCtrl.prototype.closeOrder = function() {
    this.Order.reinit();
    delete(this.selectedOrder);
    this.Items.findSelected();
  };

  /**
   * Очистить фильтр по типу техники
   */
  WarehouseItemsCtrl.prototype.closeItemTypeFilter = function() {
    delete(this.selectedFilters.item_type);
    this.reloadItems();
  }

  /**
   * Удалить ордер.
   */
  WarehouseItemsCtrl.prototype.destroyOrder = function() {
    let confirm_str = "Вы действительно хотите удалить ордер \"" + this.selectedOrder.id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Order.delete(
      { id: this.selectedOrder.id },
      (response) => {
        this.Flash.notice(response.full_message);
        this.closeOrder();
      },
      (response, status) => this.Error.response(response, status)
    );
  };
})();