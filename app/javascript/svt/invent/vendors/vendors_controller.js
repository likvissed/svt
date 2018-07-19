import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .controller('VendorsCtrl', VendorsCtrl)
    .controller('EditVendorCtrl', EditVendorCtrl);

  VendorsCtrl.$inject = ['$uibModal', '$rootScope', 'Vendors', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error'];
  EditVendorCtrl.$inject = ['$uibModalInstance', 'Server', 'Flash', 'Error'];

  function VendorsCtrl($uibModal, $rootScope, Vendors, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.$uibModal = $uibModal;
    this.$rootScope = $rootScope;
    this.Vendors = Vendors;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this._loadVendors(true);
    this._initActionCable();
  }

  VendorsCtrl.prototype._loadVendors = function(init) {
    this.Vendors.loadVendors().then(
      () => {
        this.vendors = this.Vendors.vendors;

        if (init) { return true; }

        this.$rootScope.$emit('ModelsCtrl::UpdateTableFilters', this.vendors);
      }
    );
  };

  /**
   * Инициировать подключение к каналу VendorsChannel
   */
  VendorsCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::VendorsChannel');

    consumer.subscribe(() => this._loadVendors());
  };

  /**
   * Открыть форму создания модели.
   */
  VendorsCtrl.prototype.newVendor = function() {
    this.$uibModal.open({
      templateUrl: 'editVendorModal.slim',
      controller: 'EditVendorCtrl',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  }

  /**
   * Удалить вендора
   *
   * @param vendor
   */
  VendorsCtrl.prototype.destroyVendor = function(vendor) {
    let confirm_str = "Вы действительно хотите удалить вендор \"" + vendor.vendor_name + "\"? Удаление вендора приведет к удалению всех связанных с ним моделей.";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Vendor.delete(
      { vendor_id: vendor.vendor_id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

// =====================================================================================================================

  function EditVendorCtrl($uibModalInstance, Server, Flash, Error) {
    this.$uibModalInstance = $uibModalInstance;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
  }

    /**
   * Создать модель.
   */
  EditVendorCtrl.prototype.ok = function() {
    this.Server.Invent.Vendor.save(
      { vendor: this.vendor },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      }
    );
  };
})();