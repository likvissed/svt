(function() {
  'use strict';

  app
    .controller('InventItemsCtrl', InventItemsCtrl)
    .controller('FindExistingInventItemCtrl', FindExistingInventItemCtrl);

  InventItemsCtrl.$inject = ['TablePaginator', 'InventItem', 'InventItemFiltersFactory'];
  FindExistingInventItemCtrl.$inject = ['$scope', 'InventItem', 'Flash'];

  function InventItemsCtrl(TablePaginator, InventItem, InventItemFiltersFactory) {
    this.Item = InventItem;
    this.Filters = InventItemFiltersFactory;

    this.pagination = TablePaginator.config();
    this.filters = this.Filters.getFilters();
    this.selected= this.Filters.getSelected();

    this._loadItems(true);
  }

  /**
   * Загрузить логи с сервера.
   */
  InventItemsCtrl.prototype._loadItems = function(initFlag) {
    var self = this;

    this.Item.init(initFlag).$promise.then(function() {
      self.items = self.Item.items;
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
   * Удалить выбранный фильтр по составу техники
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsCtrl.prototype.delPropFilter = function(index) {
    if (this.filters.properties.length > 1) {
      this.Filters.delProperty(index);
      this._loadItems(false);
    }
  };

// =====================================================================================================================

  function FindExistingInventItemCtrl($scope, Item, Flash) {
    this.$scope = $scope;
    this.Item = Item;
    this.Flash = Flash;

    this.selectedType = $scope.$parent.select.eqTypes[0];
    this.items = [];
  }

  /**
   * Загрузить список техники указанного типа.
   */
  FindExistingInventItemCtrl.prototype.loadItems = function() {
    var self = this;

    this.Item.loadBusyItems(this.selectedType.type_id, this.invent_num)
      .then(function(response) {
        self.items = response;
        self.$scope.$emit('removeDuplicateInvItems', self.items);

        if (response.length == 0) {
          self.Flash.alert('Техника не найдена. Проверьте корректность введенного инвентарного номера.');
          return false;
        } else if (self.items.length == 1) {
          self.Item.selectedItem = self.items[0];
        }
      });
  };

  /**
   * Очистить объект selectedItem
   */
  FindExistingInventItemCtrl.prototype.clearData = function() {
    delete(this.selectedItem);
    this.items = [];
  };
})();