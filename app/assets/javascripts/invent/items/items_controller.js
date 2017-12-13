(function() {
  'use strict';

  app.controller('InventItemsCtrl', InventItemsCtrl);

  InventItemsCtrl.$inject = ['TablePaginator', 'InventItem', 'InventItemFiltersFactory'];

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
})();