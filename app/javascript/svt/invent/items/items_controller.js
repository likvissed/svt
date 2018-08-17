import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .controller('InventItemsCtrl', InventItemsCtrl)
    .controller('FindExistingInventItemCtrl', FindExistingInventItemCtrl);

  InventItemsCtrl.$inject = ['TablePaginator', 'ActionCableChannel', 'InventItem', 'InventItemFiltersFactory', 'Server', 'Flash', 'Error'];
  FindExistingInventItemCtrl.$inject = ['$scope', 'InventItem', 'Flash'];

  function InventItemsCtrl(TablePaginator, ActionCableChannel, InventItem, InventItemFiltersFactory, Server, Flash, Error) {
    this.ActionCableChannel = ActionCableChannel
    this.Item = InventItem;
    this.Filters = InventItemFiltersFactory;
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
  InventItemsCtrl.prototype._loadItems = function(initFlag) {
    this.Item.init(initFlag).then(() => this.items = this.Item.items);
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  InventItemsCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::ItemsChannel');

    consumer.subscribe(() => this._loadItems());
  };

  /**
   * События изменения страницы.
   */
  InventItemsCtrl.prototype.changePage = function() {
    this._loadItems(false);
  };

  /**
   * Событие изменения фильтра.
   */
  InventItemsCtrl.prototype.changeFilter = function() {
    this._loadItems(false);
  };

  /**
   * Загрузить список комнат.
   */
  InventItemsCtrl.prototype.loadRooms = function() {
    this.Item.loadRooms();
  };

  /**
   * Очистить список комнат.
   */
  InventItemsCtrl.prototype.clearRooms = function() {
    this.Item.clearRooms();
  };

  /**
   * Добавить фильтр по составу техники.
   */
  InventItemsCtrl.prototype.addPropFilter = function() {
    this.Filters.addProperty();
  };

  /**
   * Удалить выбранный фильтр по составу техники.
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsCtrl.prototype.delPropFilter = function(index) {
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
  InventItemsCtrl.prototype.destroyItem = function(item) {
    let confirm_str = "Вы действительно хотите удалить " + item.type.short_description + " \"" + item.model + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Item.delete(
      { item_id: item.item_id },
      (response) => {
        this.Flash.notice(response.full_message);
        this._loadItems(false);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

// =====================================================================================================================

  function FindExistingInventItemCtrl($scope, Item, Flash) {
    this.$scope = $scope;
    this.Item = Item;
    this.Flash = Flash;

    this._setDeafultAttrs();
  }

  FindExistingInventItemCtrl.prototype._setDeafultAttrs = function() {
    this.selectedType = this.$scope.$parent.select.eqTypes[0];
    this.items = [];
  }

  /**
   * Загрузить список техники указанного типа.
   *
   * @param searchType
   */
  FindExistingInventItemCtrl.prototype.loadItems = function(searchType) {
    let message = 'Техника не найдена. ';

    message += searchType == 'invent_num' ? 'Проверьте корректность введенного инвентарного номера.' : 'Проверьте корректность введенного ID.'
    this.Item.loadBusyItems(this.selectedType.type_id, this.invent_num, this.item_id, this.$scope.$parent.division)
      .then((response) => {
        this.items = response;
        this.$scope.$emit('removeDuplicateInvItems', this.items);

        if (response.length == 0) {
          this.Flash.alert(message);
          return false;
        } else if (this.items.length == 1) {
          this.Item.selectedItem = this.items[0];
        }
      }
    );
  };

  /**
   * Очистить объект selectedItem
   */
  FindExistingInventItemCtrl.prototype.clearFindedData = function() {
    delete(this.selectedItem);
    this._setDeafultAttrs();
  };

    /**
   * Очистить данные поиска
   */
  FindExistingInventItemCtrl.prototype.clearSearchData = function() {
    this.item_id = null;
    this.invent_num = null;
  };
})();