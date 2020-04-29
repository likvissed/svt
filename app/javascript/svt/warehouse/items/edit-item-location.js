import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WarehouseEditLocationCtrl', WarehouseEditLocationCtrl);

  WarehouseEditLocationCtrl.$inject = ['$uibModalInstance', 'Flash', 'Error', 'Server', 'items'];

  function WarehouseEditLocationCtrl($uibModalInstance, Flash, Error, Server, items) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.item = items.item;
  }

  /**
   * Сохранить расположение для техники
   */
  WarehouseEditLocationCtrl.prototype.saveLocation = function() {
    this.Server.Warehouse.Item.update(
      { id: this.item.id },
      { item: this.item },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  WarehouseEditLocationCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

})();
