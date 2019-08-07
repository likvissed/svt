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
    this.item = item;
    this.$uibModalInstance = $uibModalInstance;
    this.PropertyValue = PropertyValue;
    this.WorkplaceItem = WorkplaceItem;
    this.additional = this.WorkplaceItem.getAdditional();
  }
  
  WarehousePropertyValueCtrl.prototype.runManuallyPcDialog = function() {
    this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'manuallyPcDialog.slim',
      controller: 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size: 'md',
      backdrop: 'static',
      resolve: {
        item: () => this.item
      }
    });
  };

  WarehousePropertyValueCtrl.prototype.save = function() {
    this.Server.Warehouse.Item.update(
      { id: this.item.id },
      { item: this.item },
      (response) => {
        this.Flash.notice(response.full_message),
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

  WarehousePropertyValueCtrl.prototype.destroyPropertyValues = function() {
    this.item.property_values_attributes.forEach((prop_val_value) => {
      prop_val_value.value = '';
      prop_val_value._destroy = 1;
    });
  };

})();