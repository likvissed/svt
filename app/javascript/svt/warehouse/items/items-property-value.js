import { app } from '../../app/app';
// import { runInThisContext } from 'vm';

(function () {
  'use strict';

  app
    .controller('WarehousePropertyValueCtrl', WarehousePropertyValueCtrl);

  WarehousePropertyValueCtrl.$inject = ['$uibModal', 'Flash', 'Error', 'Server', 'Config', 'item', 'WorkplaceItem', '$uibModalInstance', 'InventItem'];

  function WarehousePropertyValueCtrl($uibModal, Flash, Error, Server, Config, item, WorkplaceItem, $uibModalInstance, InventItem) {
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.Config = Config;
    this.item = item;
    this.$uibModalInstance = $uibModalInstance;
    this.additional = WorkplaceItem.getAdditional();
    this.InventItem = InventItem;
  }

  WarehousePropertyValueCtrl.prototype.runManuallyPcDialog = function() {
    this.$uibModal.open({
      animation   : this.Config.global.modalAnimation,
      templateUrl : 'manuallyPcDialog.slim',
      controller  : 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size        : 'md',
      backdrop    : 'static',
      resolve     : {
        item: () => this.item
      }
    });
    this.InventItem.setItem(this.item);
  };

  WarehousePropertyValueCtrl.prototype.save = function() {
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

  WarehousePropertyValueCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };
})();
