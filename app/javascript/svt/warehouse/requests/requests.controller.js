import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WarehouseRequestsCtrl', WarehouseRequestsCtrl);

  WarehouseRequestsCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'Config', 'WarehouseSupply', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

  function WarehouseRequestsCtrl($uibModal, TablePaginator, ActionCableChannel, Config, WarehouseSupply, WarehouseOrder, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    // console.log('WarehouseRequestsCtrl', this)
    this._loadRequests();
  }

  WarehouseRequestsCtrl.prototype._loadRequests = function() {
    this.Server.Warehouse.Request.query(
      {
        start : this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      (response) => {
        this.requests = response.data || [];
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);
      },
      (response, status) => this.Error.response(response, status)
    );
  }

  WarehouseRequestsCtrl.prototype.editRequest = function(request) {
    // console.log('editRequest', request)

    this.Server.Warehouse.Request.edit(
      { id: request.request_id },
      (response) => {
        // console.log('response', response)
        this.$uibModal.open({
          templateUrl : 'editRequestModal.slim',
          controller  : 'EditRequestCtrl',
          controllerAs: 'edit',
          size        : 'lg',
          backdrop    : 'static',
          resolve     : {
            data: {
              request: response.request,
              workers: response.workers }
          }
        });

      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

})();
