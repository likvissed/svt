import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

  SelectItemTypeCtrl.$inject = ['$scope', '$uibModalInstance', 'data', 'Workplace', 'FindExistingItemService', 'Flash'];

  function SelectItemTypeCtrl($scope, $uibModalInstance, data, Workplace, FindExistingItemService, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    // Типы оборудования
    this.eqTypes = data.eq_types;
    // Выбранный тип устройства
    this.selectedType = angular.copy(this.eqTypes[0]);
    this.SelectedItem = FindExistingItemService;
    this.Workplace = Workplace;
    // Тип техники: новая или б/у
    this.itemType = '';
    // Отдел необходим для ограничения выборки техники (в окне поиска техники)
    // $scope.division = this.Workplace.workplace.division.division;

    this.SelectedItem.clearSelectedItem();
    $scope.$on('removeDuplicateInvItems', (event, data) => {
      this._removeDuplicateItems(data);
    });
  }

  /**
   * Из массива this.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  SelectItemTypeCtrl.prototype._removeDuplicateItems = function(items) {
    let index;

    this.Workplace.workplace.items_attributes.forEach((item) => {
      index = items.findIndex((el) => el.item_id == item.id);
      if (index != -1) {
        items.splice(index, 1);
      }
    })
  };

  SelectItemTypeCtrl.prototype.ok = function() {
    if (this.itemType == 'new') {
      if (this.Workplace.validateType(this.selectedType)) {
        this.$uibModalInstance.close(this.selectedType);
      }
    } else {
      if (this.SelectedItem.selectedItem) {
        this.$uibModalInstance.close(this.SelectedItem.selectedItem);
      } else {
        this.Flash.alert('Необходимо выбрать технику.');
      }
    }
  };

  SelectItemTypeCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();