import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('InventItemsTableCtrl', InventItemsTableCtrl);

  InventItemsTableCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'InventItemsTable', 'InventItemsTableFiltersFactory', 'InventItem', 'Config', 'Server', 'Flash', 'Error'];

  function InventItemsTableCtrl($uibModal, TablePaginator, ActionCableChannel, InventItemsTable, InventItemsTableFiltersFactory, InventItem, Config, Server, Flash, Error) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel
    this.Items = InventItemsTable;
    this.Filters = InventItemsTableFiltersFactory;
    this.Item = InventItem;
    this.Config = Config;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;

    this.pagination = TablePaginator.config();
    this.filters = this.Filters.getFilters();
    this.selected= this.Filters.getSelected();

    this._loadItems(true);
    this._initActionCable();
  }

  /**
   * Загрузить данные с сервера.
   */
  InventItemsTableCtrl.prototype._loadItems = function(initFlag) {
    this.Items.init(initFlag).then(() => this.items = this.Items.items);
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  InventItemsTableCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::ItemsChannel');

    consumer.subscribe(() => this._loadItems());
  };

  /**
   * События изменения страницы.
   */
  InventItemsTableCtrl.prototype.changePage = function() {
    this._loadItems(false);
  };

  /**
   * Событие изменения фильтра.
   */
  InventItemsTableCtrl.prototype.changeFilter = function() {
    this._loadItems(false);
  };

  /**
   * Загрузить список комнат.
   */
  InventItemsTableCtrl.prototype.loadRooms = function() {
    this.Items.loadRooms();
  };

  /**
   * Очистить список комнат.
   */
  InventItemsTableCtrl.prototype.clearRooms = function() {
    this.Items.clearRooms();
  };

  /**
   * Добавить фильтр по составу техники.
   */
  InventItemsTableCtrl.prototype.addPropFilter = function() {
    this.Filters.addProperty();
  };

  /**
   * Удалить выбранный фильтр по составу техники.
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsTableCtrl.prototype.delPropFilter = function(index) {
    if (this.filters.properties.length > 1) {
      this.Filters.delProperty(index);
      this._loadItems(false);
    }
  };

  /**
   * Удалить технику.
   *
   * @param item
   */
  InventItemsTableCtrl.prototype.destroyItem = function(item) {
    let confirm_str = "Вы действительно хотите удалить " + item.type.short_description + " \"" + item.model + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Items.delete(
      { item_id: item.item_id },
      (response) => {
        this.Flash.notice(response.full_message);
        this._loadItems(false);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Редактировать состав техники
   */
  InventItemsTableCtrl.prototype.editItem = function(item) {
    this.Item.edit(item.item_id).then(
      () => {
        this.$uibModal.open({
          animation: this.Config.global.modalAnimation,
          templateUrl: 'editItem.slim',
          controller: 'EditInventItemModalCtrl',
          controllerAs: 'modal',
          size: 'md',
          backdrop: 'static'
        });
      }
    )
  }

})();