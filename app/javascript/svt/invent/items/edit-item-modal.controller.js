import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('EditInventItemModalCtrl', EditInventItemModalCtrl);

  EditInventItemModalCtrl.$inject = ['$uibModalInstance', 'InventItem'];

  function EditInventItemModalCtrl($uibModalInstance, InventItem) {
    this.$uibModalInstance = $uibModalInstance;
    this.Item = InventItem;

    this.item_o = InventItem.data;
  }

  /**
   * Закрыть модальное окно.
   */
  EditInventItemModalCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Исполнить выбранные поля ордера.
   */
  EditInventItemModalCtrl.prototype.ok = function() {
    this.Item.update().then(
      () => {
        this.$uibModalInstance.close();
      }
    )
  };
})();
