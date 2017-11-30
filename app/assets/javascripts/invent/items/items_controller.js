(function() {
  'use strict';

  app.controller('InventItemsCtrl', InventItemsCtrl);

  InventItemsCtrl.$inject = ['TableItem'];

  function InventItemsCtrl(Item) {
    this.Item = Item;
    this.pagination = Item.pagination;
    this.filters = Item.filters.selected;
    this.lists = Item.filters.lists;

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
    this.Item.addPropFilter();
  };

  /**
   * Удалить выбранный фильтр по составу техники
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsCtrl.prototype.delPropFilter = function(index) {
    if (this.filters.properties.length > 1) {
      this.Item.delPropFilter(index);
      this._loadItems(false);
    }
  };
})();