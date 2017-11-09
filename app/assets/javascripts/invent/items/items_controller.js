(function () {
  'use strict';

  app.controller('InventItemsCtrl', InventItemsCtrl);

  InventItemsCtrl.$inject = ['InvItem'];

  function InventItemsCtrl(InvItem) {
    this.InvItem = InvItem;
    this.pagination = InvItem.pagination;
    this.filters = InvItem.filters.selected;
    this.lists = InvItem.filters.lists;

    this._loadItems(true);
  }

  /**
   * Загрузить логи с сервера.
   */
  InventItemsCtrl.prototype._loadItems = function (initFlag) {
    var self = this;

    this.InvItem.init(initFlag).$promise.then(function () {
      self.items = self.InvItem.items;
    });
  };

  /**
   * События изменения страницы.
   */
  InventItemsCtrl.prototype.changePage = function () {
    this._loadItems(false);
  };

  /**
   * Событие изменения фильтра.
   */
  InventItemsCtrl.prototype.changeFilter = function () {
    this._loadItems(false);
  };

  /**
   * Добавить фильтр по составу техники.
   */
  InventItemsCtrl.prototype.addPropFilter = function () {
    this.InvItem.addPropFilter();
  };

  /**
   * Удалить выбранный фильтр по составу техники
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsCtrl.prototype.delPropFilter = function (index) {
    if (this.filters.properties.length > 1) {
      this.InvItem.delPropFilter(index);
      this._loadItems(false);
    }
  };
})();