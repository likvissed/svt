import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('EditRequestCtrl', EditRequestCtrl);

  EditRequestCtrl.$inject = ['$uibModal', '$uibModalInstance', 'Flash', 'Error', 'Server', 'request'];

  function EditRequestCtrl($uibModal, $uibModalInstance, Flash, Error, Server, request) {
    this.setFormName('request');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.request = request;
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

  // Назначить выбранного исполнителя, сохранить комментарий и изменить статус заявки как "Анализ"
  EditRequestCtrl.prototype.assignUser = function() {
    if (this.request.executor) {
      this.request.executor_fio = this.request.executor.fullName
    }

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

})();
