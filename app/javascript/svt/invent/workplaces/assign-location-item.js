import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WorkplaceAssignLocationItemCtrl', WorkplaceAssignLocationItemCtrl);

  WorkplaceAssignLocationItemCtrl.$inject = ['$uibModalInstance', 'items', 'Workplace', 'InventItem', 'WarehouseItems'];

  function WorkplaceAssignLocationItemCtrl($uibModalInstance, items, Workplace, InventItem, WarehouseItems) {
    this.$uibModalInstance = $uibModalInstance;
    this.Workplace = Workplace;
    this.InventItem = InventItem;
    this.WarehouseItems = WarehouseItems;
    this.item = items.item;
  }

  /**
   * Отправить технику на склад
   *
   * @param item
   */
  WorkplaceAssignLocationItemCtrl.prototype.sendItemToStock = function() {
    let confirm_str = `ВНИМАНИЕ! Техника будет перемещена на склад! Вы действительно хотите переместить на склад ${this.item.type.short_description}?`;

    if (!confirm(confirm_str)) { return false; }

    this.InventItem.sendToStock(this.item).then(() => {
      this.$uibModalInstance.close();
      this.Workplace.delItem(this.item)
    });
  };

  WorkplaceAssignLocationItemCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

  WorkplaceAssignLocationItemCtrl.prototype.disableButton = function() {
    if (this.WarehouseItems.completedLocation(this.item.location)) {
      return false
    }

    return true;
  };

})();
