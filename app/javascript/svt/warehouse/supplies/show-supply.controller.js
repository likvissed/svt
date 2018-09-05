import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('ShowSupplyCtrl', ShowSupplyCtrl);

  ShowSupplyCtrl.$inject = ['$uibModal', '$uibModalInstance', 'data', 'WarehouseSupply', 'Error', 'Server'];

  function ShowSupplyCtrl($uibModal, $uibModalInstance, data, WarehouseSupply, Error, Server) {
    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.Server = Server;
    this.Error = Error;
    this.supply = this.Supply.supply;
    this.extra = this.Supply.additional;
    this.selectedItem = data.item;
  }

  /**
   * Проверка, совпадает ли указанный item с выбранным (в переменной selectedItem)
   */
  ShowSupplyCtrl.prototype.isThisItem = function(item) {
    return item.id == this.selectedItem.id;
  };

    /**
   * Обновить данные поставки
   */
  ShowSupplyCtrl.prototype.reloadSupply = function() {
    this.Server.Warehouse.Supply.edit(
      { id: this.supply.id },
      (data) => this.Supply.init(data),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Закрыть модальное окно.
   */
  ShowSupplyCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
