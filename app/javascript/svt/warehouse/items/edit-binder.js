import { app } from '../../app/app';
// import { runInThisContext } from 'vm';

(function () {
  'use strict';

  app
    .controller('EditWarehouseBinderCtrl', EditWarehouseBinderCtrl);

    EditWarehouseBinderCtrl.$inject = ['$uibModal', 'Flash', 'Error', 'Server', 'Config', 'item', 'WorkplaceItem', '$uibModalInstance', 'InventItem'];

  function EditWarehouseBinderCtrl($uibModal, Flash, Error, Server, Config, item, WorkplaceItem, $uibModalInstance, InventItem) {
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.$uibModalInstance = $uibModalInstance;

    this.item = item;
  }

  EditWarehouseBinderCtrl.prototype.onSave = function() {
    // Переобразовать для обновления привязки признаков
    this.item.binders_attributes = this.item.binders;

    this.Server.Warehouse.Item.update(
      { id: this.item.id },
      { item: this.item },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  EditWarehouseBinderCtrl.prototype.onClose = function() {
    this.$uibModalInstance.dismiss();
  };
})();
