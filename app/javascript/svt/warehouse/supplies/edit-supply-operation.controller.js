import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('EditSupplyOperationCtrl', EditSupplyOperationCtrl);

  EditSupplyOperationCtrl.$inject = ['$uibModalInstance', 'operation', 'WarehouseSupply', 'WarehouseOperation', 'Error', 'Server'];

  function EditSupplyOperationCtrl($uibModalInstance, operation, WarehouseSupply, WarehouseOperation, Error, Server) {
    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.Operation = WarehouseOperation;
    this.Error = Error;
    this.Server = Server;

    this.extra = WarehouseSupply.additional;
    this.extra.update = operation ? true : false;
    this.result = {
      shiftGetterSetter: (newShift) => {
        if (angular.isDefined(newShift)) {
          this.result.shift = Math.abs(newShift);
        }

        return Math.abs(this.result.shift);
      },
      shift: this.Operation.getTemplate().shift,
      model: {
        model_id  : 0,
        item_model: ''
      },
      location: WarehouseSupply.location
    };
    this._setDefaultResult(operation);
  }

  EditSupplyOperationCtrl.prototype._setDefaultResult = function(operation) {
    this.result.type = {
      type_id          : operation ? operation.item.invent_type_id : 0,
      short_description: operation ? operation.item.item_type : ''
    };
    this.result.model = {
      model_id  : operation ? operation.item.invent_model_id : 0,
      item_model: operation ? operation.item.item_model : ''
    };
    this.result.shift = operation ? operation.shift : this.Operation.getTemplate().shift;

    // Если расположение не назначено, то присвоить пустые значения
    if (operation) {
      this.result.location = operation.item.location || angular.copy(this.result.location);
    }

    if (operation) {
      this.result.warehouseType = operation.item.warehouse_type;
      this.result.barcode = operation.item.barcode;
      this.result.inventNumStart = operation.item.invent_num_start;
      this.result.inventNumEnd = operation.item.invent_num_end;
      this.loadModels();
    }
  };

  /**
   * Очистить объект result
   */
  EditSupplyOperationCtrl.prototype.clearResult = function() {
    this._setDefaultResult();
  };

  /**
   * Загрузить список моделей
   */
  EditSupplyOperationCtrl.prototype.loadModels = function() {
    if (!this.result.type.type_id) { return false; }

    this.extra.eqModels = [];
    this.Server.Invent.Model.query(
      { type_id: this.result.type.type_id },
      (data) => this.extra.eqModels = [{ model_id: 0, item_model: 'Выберите модель' }].concat(data.data),
      (response, status) => this.Error.response(response, status)
    );
  }

  /**
   * Условия, при которых нельзя добавить позицию к поставке
   */
  EditSupplyOperationCtrl.prototype.disableButton = function() {
    if (this.result.warehouseType == 'with_invent_num') {
      if (this.completedLocation()) {
      return this.result.type.type_id == 0 || this.result.shift == 0 ||
        // Случай, когда модель выбирают из списка
        (this.result.type.type_id != 0 && this.extra.eqModels.length > 1 && this.result.model.model_id == 0) ||
        // Случай, когда модель нужно ввести вручную
        (this.result.type.type_id != 0 && this.extra.eqModels.length == 1 && !this.result.model.item_model);
      } else { return true; }
    } else if (this.result.warehouseType == 'without_invent_num') {
      return this.result.type.short_descirption == '' || this.result.model.item_model == '' || this.result.shift == 0;
    } else { return true; }
  }

  /**
   * Проверка на заполненное расположение техники
   */
  EditSupplyOperationCtrl.prototype.completedLocation = function() {
    if (!this.result.location.name) {
      // Присвоить пустое значение в name, если его не существует, чтобы сравнить с .length
      this.result.location.name = '';
    }

    if (this.result.location.room_id !== null && this.result.location.room_id !== -1) {
      return true;
    } else if (this.result.location.room_id == -1 && this.result.location.name.length != 0) {
      // если задан ввод комнаты вручную
      return true;
    }

    return false;
  }

  EditSupplyOperationCtrl.prototype.ok = function() {
    this.$uibModalInstance.close(this.result);
  }

  /**
   * Закрыть модальное окно.
   */
  EditSupplyOperationCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
