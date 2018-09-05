import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function () {
  'use strict';

  app.controller('EditSupplyCtrl', EditSupplyCtrl);

  EditSupplyCtrl.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseSupply', 'Flash', 'Error', 'Server'];

  function EditSupplyCtrl($uibModal, $uibModalInstance, WarehouseSupply, Flash, Error, Server) {
    this.setFormName('supply');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.supply = this.Supply.supply;
    this.extra = this.Supply.additional;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    // Настройка календаря 'date'
    this.date = {
      // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
      openDatePicker: false
    };
  }

  // Унаследовать методы класса FormValidationController
  EditSupplyCtrl.prototype = Object.create(FormValidationController.prototype);
  EditSupplyCtrl.prototype.constructor = EditSupplyCtrl;

  /**
   * Обновить данные поставки
   */
  EditSupplyCtrl.prototype.reloadSupply = function() {
    this.Server.Warehouse.Supply.edit(
      { id: this.supply.id },
      (data) => this.Supply.init(data),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Показать календарь.
   *
   * @param type - тип календаря, time_start или time_end
   */
  EditSupplyCtrl.prototype.openDatePicker = function() {
    this.date.openDatePicker = true;
  };

  /**
   * Добавить/Редактировать позицию
   *
   * @param operation
   */
  EditSupplyCtrl.prototype.editPosition = function(operation) {
    let modalInstance = this.$uibModal.open({
      templateUrl: 'editSupplyOperation.slim',
      controller: 'EditSupplyOperationCtrl',
      controllerAs: 'op',
      size: 'md',
      backdrop: 'static',
      resolve: { operation: operation }
    });

    modalInstance.result.then((data) => {
      operation ? this.Supply.updatePosition(operation, data) : this.Supply.addPosition(data);
    });
  }

  /**
   * Удалить позицию.
   *
   * @param operation - позиция
   */
  EditSupplyCtrl.prototype.delPosition = function(operation) {
    this.Supply.delPosition(operation);
  }

  EditSupplyCtrl.prototype.ok = function() {
    if (this.supply.id) {
      this.Server.Warehouse.Supply.update(
        { id: this.supply.id },
        { supply: this.supply },
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
      this.Server.Warehouse.Supply.save(
        { supply: this.supply },
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
  }

  /**
   * Закрыть модальное окно.
   */
  EditSupplyCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
