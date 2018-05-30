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
    var self = this;

    this.Item.init(initFlag).then(function() {
      self.items = self.Item.items;
    });
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  InventItemsCtrl.prototype._initActionCable = function() {
    var
      self = this,
      consumer = new this.ActionCableChannel('Invent::ItemsChannel');

    consumer.subscribe(function() {
      self._loadItems();
    });
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
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить " + item.type.short_description + " \"" + item.model + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Item.delete(
      { item_id: item.item_id },
      function(response) {
        self.Flash.notice(response.full_message);
        self._loadItems(false);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
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
    var
      self = this,
      message = 'Техника не найдена. ';

    message += searchType == 'invent_num' ? 'Проверьте корректность введенного инвентарного номера.' : 'Проверьте корректность введенного ID.'
    this.Item.loadBusyItems(this.selectedType.type_id, this.invent_num, this.item_id, this.$scope.$parent.division)
      .then(function(response) {
        self.items = response;
        self.$scope.$emit('removeDuplicateInvItems', self.items);

        if (response.length == 0) {
          self.Flash.alert(message);
          return false;
        } else if (self.items.length == 1) {
          self.Item.selectedItem = self.items[0];
        }
      });
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