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
    this.list_recommendations = data.list_recommendations;
    this.list_recommendations.unshift({ 'id': -1, 'name': 'Выберите рекомендацию' });

    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.tabs = {
      user : true,
      req  : true,
      order: true
    }

    // Найти выбранного исполнителя для возможности смены
    if (this.request.executor_fio) {
      this.request.executor = this.workers.find((attr) => {
        return attr.fullname == this.request.executor_fio;
      });
    }

    // Заблокировать кнопку пока отправляется список рекомендаций в SSD
    this.loadOwner = true;
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

  // Переназначить исполнителя заявки (Чтобы только выбранный пользователь мог создать ордер на эту заявку)
  EditRequestCtrl.prototype.assignNewWorker = function() {
    if (!this.request.executor) {
      this.Flash.alert('Необходимо выбрать исполнителя');

      return false;
    }

    this.Server.Warehouse.Request.assignNewExecutor(
      { id: this.request.request_id },
      { executor: this.request.executor },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

  // Утвердить расходный ордер и изменить статус заявки как "Ожидает подтверждения пользователя"
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

  // Изменить статус заявки как "Готов к выдаче" и отправка уведомления об этому пользователю
  EditRequestCtrl.prototype.readyRequest = function() {
    this.Server.Warehouse.Request.ready(
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

  // Изменить статус заявки как "На подписи у начальника" и отправить в ССД
  EditRequestCtrl.prototype.sendToOwner = function() {
    if (!this.owner) {
      this.Flash.alert('Необходимо выбрать руководителя');

      return false;
    }

    if (!confirm('Вы действительно хотите отправить список рекомендаций на подпись?')) { return false; }

    this.loadOwner = false;

    this.Server.Warehouse.Request.sendToOwner(
      { id: this.request.request_id },
      {
        request: this.request,
        owner  : this.owner
      },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.loadOwner = true;
      }
    );
  }

  EditRequestCtrl.prototype.updateComment = function() {
    this.Server.Warehouse.Request.update(
      { id: this.request.request_id },
      { request: this.request },
      (response) => {
        this.Flash.notice(response.full_message);
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

  EditRequestCtrl.prototype.addRecommendation = function() {
    if (this.request.recommendation_json === null) {
      this.request.recommendation_json = [];
    }

    this.request.recommendation_json.push(this.list_recommendations[0]);
  };

  EditRequestCtrl.prototype.deleteRecommendation = function(index) {
    this.request.recommendation_json.splice(index, 1);

    if (this.request.recommendation_json.length == 0) {
      this.request.recommendation_json = null;
    }
  };

  // Сохранить список рекомендаций и изменить статус заявки как "Ожидает отправки в ССД"
  EditRequestCtrl.prototype.saveRecommendation = function() {
    if (this.request.recommendation_json === null) {
      this.Flash.alert('Необходимо заполнить список рекомендаций');

      return false;
    }

    this.Server.Warehouse.Request.saveRecommendation(
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

  // Изменить статус заявки как "Ожидание наличия техники"
  EditRequestCtrl.prototype.expectedInStock = function(flag) {
    if (!confirm('Вы действительно хотите изменить статус заявки?')) { return false; }

    this.Server.Warehouse.Request.expectedInStock(
      { id: this.request.request_id },
      { flag: flag },
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
