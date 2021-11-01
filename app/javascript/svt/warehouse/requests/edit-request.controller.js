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

    // console.log('EditCtrl', this)
  }

  // Унаследовать методы класса FormValidationController
  EditRequestCtrl.prototype = Object.create(FormValidationController.prototype);
  EditRequestCtrl.prototype.constructor = EditRequestCtrl;

})();
