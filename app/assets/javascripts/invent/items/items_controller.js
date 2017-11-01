(function () {
  'use strict';

  app.controller('InventItemsCtrl', InventItemsCtrl);

  InventItemsCtrl.$inject = ['InvItem'];

  function InventItemsCtrl(InvItem) {
    this.InvItem = InvItem;
    this.pagination = InvItem.pagination;

    this._loadItems();
  }

  /**
   * Загрузить логи с сервера.
   */
  InventItemsCtrl.prototype._loadItems = function () {
    var self = this;

    this.InvItem.init().$promise.then(function () {
      self.items = self.InvItem.items;
    });
  };

  /**
   * События изменения страницы.
   */
  InventItemsCtrl.prototype.pageChanged = function () {
    this._loadItems();
  };
})();