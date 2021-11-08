import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('EditRequestCtrl', EditRequestCtrl);

  EditRequestCtrl.$inject = ['$uibModal', '$uibModalInstance', 'Flash', 'Error', 'Server', 'data'];

  function EditRequestCtrl($uibModal, $uibModalInstance, Flash, Error, Server, data) {
    this.setFormName('request');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.request = data.request;
    this.workers = data.workers;

    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.tabs = {
      user : true,
      req  : true,
      order: true
    }

  }

  // Унаследовать методы класса FormValidationController
  EditRequestCtrl.prototype = Object.create(FormValidationController.prototype);
  EditRequestCtrl.prototype.constructor = EditRequestCtrl;

  EditRequestCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  }

  EditRequestCtrl.prototype.setExecutor = function() {
    this.request.executor_fio = this.request.executor.fullname;
    this.request.executor_tn = this.request.executor.tn;
  }

  // Закрыть заявку
  EditRequestCtrl.prototype.closeRequest = function() {
    let confirm_str = 'Вы действительно хотите закрыть заявку?';

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Request.close(
      { id: this.request.request_id },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

  // Назначить выбранного исполнителя, сохранить комментарий и изменить статус заявки как "Обработка"
  EditRequestCtrl.prototype.sendForAnalysis = function() {
    this.Server.Warehouse.Request.sendForAnalysis(
      { id: this.request.request_id },
      { request: this.request },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

  // Утвердить расходный ордер и изменить статус заявки как "Ожидает подтверждение от пользователя"
  EditRequestCtrl.prototype.confirmRequestAndOrder = function() {
    this.Server.Warehouse.Request.confirmRequestAndOrder(
      { id: this.request.request_id },
      { order_id: this.request.order.id },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

})();
