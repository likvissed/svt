import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('ItemsForOrderController', ItemsForOrderController)

  ItemsForOrderController.$inject = ['$scope', '$uibModalInstance', 'WarehouseOrder', 'FindExistingItemService', 'Flash', 'WarehouseItems'];

  function ItemsForOrderController($scope, $uibModalInstance, WarehouseOrder, FindExistingItemService, Flash, WarehouseItems) {
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.FindExistingItemService = FindExistingItemService;
    this.Flash = Flash;
    this.Items = WarehouseItems;

    this.eqTypes = WarehouseOrder.additional.eqTypes;
    this.warehouseType = 'with_invent_num';
    this.manuallyItem = {
      item_model: '',
      item_type : ''
    };
    this.item = {};

    // Инвентарный номер выбранного типа техники
    this.invent_num = '';
    // Отдел необходим для ограничения выборки техники (в окне поиска техники)
    $scope.division = this.Order.order.consumer_dept;
    // Обязательно необходимо сбросить объект selectedItem
    this.FindExistingItemService.selectedItem = null;

    $scope.$on('removeDuplicateInvItems', (event, data) => this._removeDuplicateItems(data));
  }

  /**
   * Из массива this.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  ItemsForOrderController.prototype._removeDuplicateItems = function(items) {
    let index;

    this.Order.order.operations_attributes.forEach(function(attr) {
      if (!attr.inv_item_ids) { return false; }

      index = items.findIndex((el) => attr.inv_item_ids.includes(el.item_id));
      if (index != -1) {
        items.splice(index, 1);
      }
    });
  };

  ItemsForOrderController.prototype.ok = function() {
    if (this.warehouseType == 'with_invent_num') {
      if (!this.FindExistingItemService.selectedItem) {
        this.Flash.alert('Необходимо указать инвентарный номер (или ID) и выбрать технику');

        return false;
      }
      if (!this.Items.completedLocation(this.item.location)) {
        this.Flash.alert('Необходимо назначить расположение: площадка, корпус, комната');

        return false;
      }
    }

    if (this.warehouseType == 'without_invent_num' && !this.manuallyItem.item_model && !this.manuallyItem.item_type) {
      this.Flash.alert('Необходимо указать тип и наименование техники');

      return false;
    }

    let result = {
      warehouseType: this.warehouseType,
      item         : this.warehouseType == 'with_invent_num' ? this.FindExistingItemService.selectedItem : this.manuallyItem
    };

    // Присвоение выбранного расположения
    result.item.location = this.item.location;

    this.$uibModalInstance.close(result);
  };

  ItemsForOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
