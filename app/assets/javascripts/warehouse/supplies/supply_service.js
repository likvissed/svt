(function () {
  'use strict';

  app.service('WarehouseSupply', WarehouseSupply);

  WarehouseSupply.$inject = ['WarehouseOperation', 'Server', 'Config', 'Flash', 'Error'];

  function WarehouseSupply(WarehouseOperation, Server, Config, Flash, Error) {
    this.Operation = WarehouseOperation;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.additional = {};
    this.order = {};
  }

  WarehouseSupply.prototype._initSupply = function(supply) {
    this.supply = supply;
    this.supply.date = this.supply.date ? new Date(this.supply.date) : '';
    this.supply.operations_attributes = supply.operations_attributes || [];
  }

  /**
   * Инициализация данных
   *
   * @param data
   */
  WarehouseSupply.prototype.init = function(data) {
    this._initSupply(data.supply);
    this.Operation.setTemplate(data.operation);

    this.additional.eqTypes = [{ type_id: 0, short_description: 'Выберите тип' }].concat(data.eq_types);
    this.additional.visibleCount = this.supply.operations_attributes.length || 0;
  }

  /**
   * Добавить позицию к поставке
   *
   * @param data
   */
  WarehouseSupply.prototype.addPosition = function(data) {
    this.supply.operations_attributes.push(this.Operation.generate(null, data));
    this.additional.visibleCount ++;
  }

  /**
   * Изменить данные позиции
   */
  WarehouseSupply.prototype.updatePosition = function(operation, data) {
    var index = this.supply.operations_attributes.indexOf(operation);
    this.Operation.update(this.supply.operations_attributes[index], data);
  }

  /**
   * Удалить позицию
   *
   * @param operation
   */
  WarehouseSupply.prototype.delPosition = function(operation) {
    if (operation.id) {
      operation._destroy = 1;
    } else {
      var index = this.supply.operations_attributes.indexOf(operation);
      this.supply.operations_attributes.splice(index, 1);
    }

    this.additional.visibleCount --;
  }
})();