import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('EditInOrderController', EditInOrderController);

  EditInOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

  function EditInOrderController($uibModal, $uibModalInstance, WarehouseOrder, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.extra = this.Order.additional;

    // this.selectedConsumer = this.extra.users.find(function(el) { return el.id_tn == self.order.consumer_id_tn; }) || {};
  }

  // Унаследовать методы класса FormValidationController
  EditInOrderController.prototype = Object.create(FormValidationController.prototype);
  EditInOrderController.prototype.constructor = EditInOrderController;

  /**
   * Обновить данные ордера
   */
  EditInOrderController.prototype.reloadOrder = function() {
    this.Order.reloadOrder();
  };

  /**
   * Открыть форму добавления техники в позицию ордера
   */
  EditInOrderController.prototype._openFormToAddExistingItem = function() {
    let modalInstance = this.$uibModal.open({
      templateUrl : 'existingItem.slim',
      controller  : 'ItemsForOrderController',
      controllerAs: 'select',
      size        : 'md',
      backdrop    : 'static'
    });

    modalInstance.result.then((result) => {
      this.Order.addPosition(result.warehouseType, result.item);
    });
  };

  /**
   * Событие выбора отдела.
   */

  /**
   * EditInOrderController.prototype.changeDivision = function() {
   *   this.selectedConsumer = {};
   *   this.Order.setConsumer();
   *   this.Order.loadUsers();
   * };
   */

  /**
   * Установить параметры пользователя, сдающего технику
   */

  /**
   * EditInOrderController.prototype.changeConsumer = function() {
   *   this.Order.setConsumer(this.selectedConsumer);
   * };
   */

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param obj - объект выбранного ответственного.
   */
  EditInOrderController.prototype.formatLabel = function(obj) {
    if (!this.extra.users) { return ''; }

    for (let i = 0; i < this.extra.users.length; i++) {
      if (obj.id_tn === this.extra.users[i].id_tn) {
        return this.extra.users[i].fio;
      }
    }
  };

  /**
   * Добавить позицию
   */
  EditInOrderController.prototype.addPosition = function() {
    if (this.order.status == 'done') { return false; }
    this._openFormToAddExistingItem();
  };

  /**
   * Убрать позицию
   */
  EditInOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
  };

  /**
   * Создать ордер
   *
   * @param done - если true, ордер будет сразу же исполнен
   */
  EditInOrderController.prototype.ok = function(done = false) {
    let sendData = this.Order.getObjectToSend(done);

    if (done && !confirm('Вы действительно хотите создать ордер и сразу же его исполнить? Удалить исполненый ордер или отменить его исполнение невозможно')) {
      return false;
    }

    if (this.order.id) {
      this.Server.Warehouse.Order.updateIn(
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
    } else {
      this.Server.Warehouse.Order.saveIn(
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
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditInOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
