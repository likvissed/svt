import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('EditItemPropertyValuesCtrl', EditItemPropertyValuesCtrl);

  EditItemPropertyValuesCtrl.$inject = ['InventItem', '$uibModal', 'Flash'];

  function EditItemPropertyValuesCtrl(InventItem, $uibModal, Flash) {
    this.data = InventItem.data;
    this.$uibModal = $uibModal;
    this.Flash = Flash;
  }

  /**
   * Добавить новый картридж и сразу исполнить приходный и расходный ордер
   */
  EditItemPropertyValuesCtrl.prototype.addNewCartridge = function() {
    if (this.data.item.status != 'in_workplace' || !this.data.item.workplace_id) {
      this.Flash.alert('Статус техники не соответствует статусу "На рабочем месте"');

      return false;
    }

    this.$uibModal.open({
      templateUrl : 'AddCartridgeItemCtrl.slim',
      controller  : 'EditItemPropValCartridgeCtrl',
      controllerAs: 'edit',
      backdrop    : 'static',
      size        : 'md',
      resolve     : {
        item: () => {
          return { item_id: this.data.item.id };
        }
      }
    }).result.then(function(){
      location.reload();
    });
  };

})();
