import { app } from '../../app/app';
import { runInThisContext } from 'vm';

(function () {
  'use strict';

  app
    .controller('WarehousePropertyValueCtrl', WarehousePropertyValueCtrl);

  WarehousePropertyValueCtrl.$inject = ['$uibModal', 'TablePaginator', 'Flash', 'Error', 'Server', 'Config', 'item', 'WorkplaceItem', 'PropertyValue', '$uibModalInstance'];

  function WarehousePropertyValueCtrl($uibModal, TablePaginator, Flash, Error, Server, Config, item, WorkplaceItem, PropertyValue, $uibModalInstance) {
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.items = item;
    this.$uibModalInstance = $uibModalInstance;
    this.PropertyValue = PropertyValue;
    this.WorkplaceItem = WorkplaceItem;
    this.additional = this.WorkplaceItem.getAdditional();
  }
  
  WarehousePropertyValueCtrl.prototype.runManuallyPcDialog = function() {
    
    this.WorkplaceItem.setAdditional('pcAttrs', this.items.file_depending);
    this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'manuallyPcDialog.slim',
      controller: 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size: 'md',
      backdrop: 'static',
      resolve: {
        item: () => this.items
      }
    });
  };

  WarehousePropertyValueCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

})();