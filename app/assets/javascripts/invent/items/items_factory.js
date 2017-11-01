(function () {
  'use strict';

  app.service('InvItem', InvItem);

  InvItem.$inject = ['Config', 'Server', 'Error'];

  function InvItem(Config, Server, Error) {
    this.Config = Config;
    this.Server = Server;
    this.Error = Error;

    this.pagination = {
      totalEvents: 0,
      currentPage: 1,
      maxSize: 5
    };
  }

  /**
   * Инициализация данных.
   */
  InvItem.prototype.init = function () {
    var
      self = this,
      start = (this.pagination.currentPage - 1) * this.Config.global.uibPaginationConfig.itemsPerPage;

    return this.Server.Invent.Item.query(
      {
        start: start,
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      function (response) {
        self.items = response.data;
        console.log(self.items);
        self.pagination.totalEvents = response.totalRecords;
      },
      function (response, status) {
        self.Error.response(response, status)
      });
  };
})();