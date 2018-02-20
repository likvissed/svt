(function () {
  'use strict';

  app
    .controller('WarehouseItemsCtrl', WarehouseItemsCtrl);

  WarehouseItemsCtrl.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'WarehouseItems', 'Order', 'Flash', 'Error', 'Server'];

  function WarehouseItemsCtrl($uibModal, ActionCableChannel, TablePaginator, WarehouseItems, Order, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Items = WarehouseItems;
    this.Order = Order;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

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

    this.Items.loadItems().then(
      function(response) {
        self.items = self.Items.items;

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
   * Открыть модальное окно
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
      self.Order.reinit();
    });
  };

  /**
   * События изменения страницы.
   */
  WarehouseItemsCtrl.prototype.changePage = function() {
    this._loadItems();
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
      var operation = this.order.operations_attributes.find(function(op) { return op.warehouse_item_id == item.warehouse_item_id; })

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
      { warehouse_item_id: item.warehouse_item_id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
    };
})();