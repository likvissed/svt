import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('DeliveryItemsCtrl', DeliveryItemsCtrl);

  DeliveryItemsCtrl.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

  function DeliveryItemsCtrl($uibModal, $uibModalInstance, WarehouseOrder, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
  }

  // Унаследовать методы класса FormValidationController
  DeliveryItemsCtrl.prototype = Object.create(FormValidationController.prototype);
  DeliveryItemsCtrl.prototype.constructor = DeliveryItemsCtrl;

  /**
   * Обновить данные техники указанной оперции.
   *
   * @param inv_item
   */
  DeliveryItemsCtrl.prototype.refreshInvItemData = function(inv_item) {
    if (!inv_item.id) { return false; }

    this.Server.Invent.Item.get(
      { item_id: inv_item.id },
      (response) => angular.extend(inv_item, response),
      (response, status) => this.Error.response(response, status)
    )
  };

  /**
   * Распечатать ордер.
   */
  DeliveryItemsCtrl.prototype.printOrder = function() {
    let sendData = this.Order.getObjectToSend();

    window.open('/warehouse/orders/' + this.order.id + '/print?order=' + JSON.stringify(sendData), '_blank');
  };

  /**
   * Выдать технику.
   */
  DeliveryItemsCtrl.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    this.Server.Warehouse.Order.executeOut(
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
    );
  };

  /**
   * Закрыть окно.
   */
  DeliveryItemsCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Фильтр, определяющий, какие операции только что были выбраны пользователем для исполнения.
   */
  DeliveryItemsCtrl.prototype.selectedOpFilter = function(selectedOp) {
    return function(op) {
      return selectedOp.find((el) => el.id == op.id);
    }
  };
})();