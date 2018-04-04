(function () {
  'use strict';

  app
    .controller('WarehouseItemsCtrl', WarehouseItemsCtrl);

  WarehouseItemsCtrl.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'WarehouseItems', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

  function WarehouseItemsCtrl($uibModal, ActionCableChannel, TablePaginator, WarehouseItems, WarehouseOrder, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Items = WarehouseItems;
    this.Order = WarehouseOrder;
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
    var
      self = this,
      consumer = new this.ActionCableChannel('Warehouse::ItemsChannel');

    consumer.subscribe(function() {
      self._loadItems();
    });
  };

  /**
   * Загрузить список ордеров.
   */
  WarehouseItemsCtrl.prototype._loadItems = function(init) {
    var self = this;

    this.Items.loadItems(init).then(
      function(response) {
        self.items = self.Items.items;
        self.orders = response.orders || [];

        if (init) {
          self.Order.init('out', response.order);
          self.order = self.Order.order;
          self.extraOrder = self.Order.additional;
        } else {
          self.Items.findSelected();
        }
      }
    );
  };

  /**
   * Открыть модальное окно.
   */
  WarehouseItemsCtrl.prototype._openEditModal = function() {
    var self = this;
    var modalInstance = this.$uibModal.open({
      templateUrl: 'outOrderModal.slim',
      controller: 'EditOutOrderController',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });

    modalInstance.result.then(function(result) {
      self.closeOrder();
    });
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
    var operation = this.isItemInOrder(item);
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
    this.selectedFilters.showOnlyPresence = !this.selectedFilters.showOnlyPresence;
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
      var operation = this.Order.getOperation(item);

      this.Order.delPosition(operation);
    }
  };

  /**
   * Открыть окно создания ордера.
   */
  WarehouseItemsCtrl.prototype.newOrder = function() {
    this._openEditModal();
  };

  /**
   * Удалить технику со склада
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype.destroyItem = function(item) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить \"" + item.item_type + "\" со склада?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Warehouse.Item.delete(
      { id: item.id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };

  /**
   * Загрузить ордера для редактирования
   *
   * @param order
   */
  WarehouseItemsCtrl.prototype.loadOrder = function() {
    var self = this;

    this.Order.loadOrder(this.selectedOrder.id, true).then(function() {
      self._openEditModal();
      self.Items.findSelected();

      self.reloadItems();
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
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить ордер \"" + this.selectedOrder.id + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Warehouse.Order.delete(
      { id: this.selectedOrder.id },
      function(response) {
        self.Flash.notice(response.full_message);
        self.closeOrder();
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };
})();