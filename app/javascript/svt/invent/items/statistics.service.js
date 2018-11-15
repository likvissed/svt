import { app } from '../../app/app';

(function() {
  'use strict';

  app.service('Statistics', Statistics);

  Statistics.$inject = ['Server', 'Error'];

  function Statistics(Server, Error) {
    this.Server = Server;
    this.Error = Error;
  }

  /**
   * Загрузить статистику с сервера.
   *
   * @param type
   */
  Statistics.prototype.get = function(type) {
    return this.Server.Statistics.get(
      { type: type },
      (response) => this.data = response,
      (response, status) => this.Error.response(response, status)
    ).$promise;
  }
})();
