import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('FindExistingInventItemCtrl', FindExistingInventItemCtrl);

  FindExistingInventItemCtrl.$inject = ['$scope', 'FindExistingItemService', 'Flash'];

  function FindExistingInventItemCtrl($scope, FindExistingItemService, Flash) {
    this.$scope = $scope;
    this.Item = FindExistingItemService;
    this.Flash = Flash;

    this._setDeafultAttrs();
  }

  FindExistingInventItemCtrl.prototype._setDeafultAttrs = function() {
    this.selectedType = this.$scope.$parent.select.eqTypes[0];
    this.items = [];
  };

  /**
   * Загрузить список техники.
   */
  FindExistingInventItemCtrl.prototype.loadItems = function() {
    this.Item.loadBusyItems(this.selectedType.type_id, this.invent_num, this.barcode_item, this.$scope.$parent.division)
      .then(() => {
        this.items = this.Item.items;
        this.$scope.$emit('removeDuplicateInvItems', this.items);

        // Запрет на добавление дублирующей операции с одинаковой техникой и вывода ошибки "Необходимо указать инвентарный номер (или штрих-код) и выбрать технику"
        if (this.items.length == 0) {
          this.$scope.$parent.select.FindExistingItemService.selectedItem = null;
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
    this.barcode_item = null;
    this.invent_num = null;
  };
})();
