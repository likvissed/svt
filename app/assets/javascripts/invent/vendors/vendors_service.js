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
    var self = this;

    return this.Server.Invent.Vendor.query(
      function(response) {
        self.vendors = response;
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    ).$promise;
  }
})();