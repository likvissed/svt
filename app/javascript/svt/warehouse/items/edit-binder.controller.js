import { app } from '../../app/app';

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
    if (!this.validate()) {
      this.Flash.alert('Необходимо выбрать признак');

      return false;
    }
    this._onPrepareBinders();

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

  EditWarehouseBinderCtrl.prototype.validate = function() {
    let sign_null = this.item.binders.find((el) => {
      return el.sign_id === null;
    })

    if (sign_null) {
      return false;
    } else {
      return true;
    }
  };

  EditWarehouseBinderCtrl.prototype._onPrepareBinders = function() {
    // Переобразовать для обновления привязки признаков
    this.item.binders_attributes = this.item.binders;

    // Назначить id warehouse_item
    this.item.binders_attributes.forEach((value) => value.warehouse_item_id = this.item.id);
  };

  EditWarehouseBinderCtrl.prototype.onClose = function() {
    this.$uibModalInstance.dismiss();
  };
})();
