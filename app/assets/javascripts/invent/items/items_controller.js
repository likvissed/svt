(function () {
  'use strict';

  class InventItemsCtrl {
    constructor(InvItem) {
      this._InvItem = InvItem;

      this._loadItems(true);
    }

    /**
     * Загрузить логи с сервера.
     */
    _loadItems(initFlag) {
      this._InvItem.init(initFlag).$promise.then(() => this.items = this._InvItem.items)
    }

    get filters() {
      return this._InvItem.filters.selected;
    }

    get lists() {
      return this._InvItem.filters.lists;
    }

    get pagination() {
      return this._InvItem.pagination;
    }

    /**
     * События изменения номера страницы.
     */
    changePage() {
      this._loadItems(false);
    }

    /**
     * Событие изменения фильтра.
     */
    changeFilter() {
      this._loadItems(false);
    }

    /**
     * Добавить фильтр по составу техники.
     */
    addPropFilter() {
      this._InvItem.addPropFilter();
    }

    /**
     * Удалить выбранный фильтр по составу техники
     *
     * @param index - индекс удаляемого элемента.
     */
    delPropFilter(index) {
      if (this.filters.properties.length > 1) {
        this._InvItem.delPropFilter(index);
        this._loadItems(false);
      }
    }
  }

  app.controller('InventItemsCtrl', InventItemsCtrl);

  InventItemsCtrl.$inject = ['InvItem'];
})();