import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('EditOutOrderController', EditOutOrderController);

  EditOutOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'WarehouseItems', 'Flash', 'Error', 'Server'];

  function EditOutOrderController($uibModal, $uibModalInstance, WarehouseOrder, WarehouseItems, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Items = WarehouseItems;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.extra = this.Order.additional;

    this._createShiftGetterSetter();
  }

  // Унаследовать методы класса FormValidationController
  EditOutOrderController.prototype = Object.create(FormValidationController.prototype);
  EditOutOrderController.prototype.constructor = EditOutOrderController;

  EditOutOrderController.prototype._createShiftGetterSetter = function() {
    this.order.createShiftGetterSetter = function(op) {
      op.shiftGetterSetter = function(newShift) {
        if (angular.isDefined(newShift)) {
          op.shift = -newShift;
        }

        return Math.abs(op.shift);
      };

      return op.shiftGetterSetter;
    }
  };

  /**
   * Обновить данные ордера.
   */
  EditOutOrderController.prototype.reloadOrder = function() {
    this.Order.reloadOrder();
    this._createShiftGetterSetter();
  };

  /**
   * Убрать позицию.
   */
  EditOutOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);

    let item = this.Items.items.find((item) => item.id == operation.item_id)
    if (item) {
      item.added_to_order = false;
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditOutOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Создать ордер.
   */
  EditOutOrderController.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    if (this.order.id) {
      this.Server.Warehouse.Order.updateOut(
        { id: this.order.id },
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    } else {
      this.Server.Warehouse.Order.saveOut(
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    }
  };
})();
