import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('EditWriteOffOrderController', EditWriteOffOrderController);

  EditWriteOffOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'WarehouseItems', 'Flash', 'Error', 'Server'];

  function EditWriteOffOrderController($uibModal, $uibModalInstance, WarehouseOrder, WarehouseItems, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Items = WarehouseItems;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
  }

  /**
   * Убрать позицию
   */
  EditWriteOffOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
    this.Items.items.find((item) => item.id == operation.item_id).added_to_order = false
  };

  /**
   * Создать ордер.
   */
  EditWriteOffOrderController.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    if (this.order.id) {
      this.Server.Warehouse.Order.updateWriteOff(
        { id: this.order.id },
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => this.Error.response(response, status)
      );
    } else {
      this.Server.Warehouse.Order.saveWriteOff(
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => this.Error.response(response, status)
      );
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditWriteOffOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();