import { app } from '../../app/app';

(function () {
  'use strict';

  app.service('Vendors', Vendors);

  Vendors.$inject = ['Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Vendors(Server, TablePaginator, Config, Flash, Error) {
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
  }

  Vendors.prototype.loadVendors = function() {
    return this.Server.Invent.Vendor.query(
      (response) => this.vendors = response,
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };
})();
