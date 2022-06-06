import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .controller('WarehouseItemsCtrl', WarehouseItemsCtrl);

  WarehouseItemsCtrl.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'WarehouseItems', 'WarehouseOrder', 'WarehouseSupply', 'Flash', 'Error', 'Server', 'Config', 'WorkplaceItem', 'InventItem'];

  function WarehouseItemsCtrl($uibModal, ActionCableChannel, TablePaginator, WarehouseItems, WarehouseOrder, WarehouseSupply, Flash, Error, Server, Config, WorkplaceItem, InventItem) {
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
    this.Config = Config;
    this.TablePaginator = TablePaginator;
    this.WorkplaceItem = WorkplaceItem;
    this.InventItem = InventItem;

    this._loadItems(true);
    this._initActionCable();
  }

  /**
   * Инициировать подключение к каналу ItemsChannel.
   */
  WarehouseItemsCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Warehouse::ItemsChannel');

    consumer.subscribe(() => {
      // this.closeOrder();
      this._loadItems();
    });
  };

  /**
   * Загрузить список ордеров.
   *
   * @param init - флаг. Если true, будут загружены и фильтры
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
      templateUrl : `edit${type}OrderModal.slim`,
      controller  : `Edit${type}OrderController`,
      controllerAs: 'edit',
      size        : 'md',
      backdrop    : 'static'
    });

    modalInstance.result.then(() => this.closeOrder());
  };

  /**
   * Открыть модальное окно для просмотра состава поставки.
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype._openSupplyModal = function(item) {
    this.$uibModal.open({
      templateUrl : 'showSupplyModal.slim',
      controller  : 'ShowSupplyCtrl',
      controllerAs: 'show',
      size        : 'md',
      backdrop    : 'static',
      resolve     : {
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
   * Загрузить комнаты выбранного корпуса.
   */
  WarehouseItemsCtrl.prototype.loadRooms = function() {
    this.clearRooms();

    this.Server.Warehouse.Location.rooms(
      { building_id: this.selectedFilters.building_id },
      (data) => this.filters.rooms = data,
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Очистить список комнат.
   */
  WarehouseItemsCtrl.prototype.clearRooms = function() {
    delete(this.filters.rooms);
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
        operationName = operation == 'out' ? 'Out' : 'WriteOff';
        this._openOrderModal(operationName);
      }
    );
  };

  /**
   * Открыть окно обновления ордера.
   *
   * @param operation
   */
  WarehouseItemsCtrl.prototype.showOrder = function(operation) {
    let operationName = operation == 'out' ? 'Out' : 'WriteOff';

    this._openOrderModal(operationName);
  };

  /**
   * Удалить технику со склада.
   *
   * @param item
   */
  WarehouseItemsCtrl.prototype.destroyItem = function(item) {
    let confirm_str = `Вы действительно хотите удалить "${item.item_type}" со склада?`;

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Item.delete(
      { id: item.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Загрузить ордер для редактирования.
   */
  WarehouseItemsCtrl.prototype.loadOrder = function() {
    let operationName;

    this.Order.loadOrder(this.selectedOrder.id, true).then(() => {
      operationName = this.selectedOrder.operation == 'out' ? 'Out' : 'WriteOff';
      this._openOrderModal(operationName);
      this.Items.findSelected();

      this.reloadItems();
    });
  }

  /**
   * Очистить выбранный ордер.
   */
  WarehouseItemsCtrl.prototype.closeOrder = function() {
    this.Order.reinit();
    delete(this.selectedOrder);
    this.Items.findSelected();
  };

  /**
   * Очистить фильтр по типу техники.
   */
  WarehouseItemsCtrl.prototype.closeItemTypeFilter = function() {
    delete(this.selectedFilters.item_type);
    this.reloadItems();
  }

  /**
   * Удалить ордер.
   */
  WarehouseItemsCtrl.prototype.destroyOrder = function() {
    let confirm_str = `Вы действительно хотите удалить ордер "${this.selectedOrder.id}"?`;

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

  WarehouseItemsCtrl.prototype.editItem = function(item) {
    this.Server.Warehouse.Item.edit(
      {
        start : this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        id    : item.id
      },
      (response) => {
        this.item = response.item;
        this.item.type_id = this.item.invent_type_id;
        delete(item.invent_type_id);

        this.WorkplaceItem.setTypes(response.prop_data.eq_types);
        this.WorkplaceItem.setAdditional('pcAttrs', response.prop_data.file_depending);
        this.WorkplaceItem.setAdditional('pcTypes', response.prop_data.type_with_files);
        this.WorkplaceItem.getTypesItem(this.item);

        this.openEditItem(this.item);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  WarehouseItemsCtrl.prototype.openEditItem = function(item) {
    // Для загрузки свойств техники
    this.InventItem.setItem(item);

    this.$uibModal.open({
      templateUrl : 'WarehousePropertyValueEditCtrl.slim',
      controller  : 'WarehousePropertyValueCtrl',
      controllerAs: 'edit',
      backdrop    : 'static',
      size        : 'md',
      resolve     : {
        item: () => item
      }
    });
  };

  WarehouseItemsCtrl.prototype.editLocationItem = function(item) {
    this.Server.Warehouse.Item.edit(
      {
        id: item.id
      },
      (response) => {
        this.item = response.item;
        this.Items.openEditLocationItem(this.item);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  WarehouseItemsCtrl.prototype.onEditBinder = function(item) {
    this.$uibModal.open({
      templateUrl : 'EditWarehouseBinder.slim',
      controller  : 'EditWarehouseBinderCtrl',
      controllerAs: 'edit',
      backdrop    : 'static',
      size        : 'lg',
      resolve     : {
        item: () => item
      }
    });
  };


})();
