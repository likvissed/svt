import { app } from '../../app/app';

(function() {
  app.factory('myHttpInterceptor', myHttpInterceptor);

  myHttpInterceptor.$inject = ['$q'];

  /**
   * Фабрика для настройки параметрв для индикатора выполнения ajax запросов
   *
   * @class SVT.myHttpInterceptor
   */
  function myHttpInterceptor($q) {
    this.requests = {
      count: 0
    };

    /**
     * Увеличить счетчик запросов.
     */
    let incCount = () => this.requests.count++;

    /**
     * Уменьшить счетчик запросов.
     */
    let decCount = () => this.requests.count--;

    return {
      getRequestsCount: this.requests,
      incCount        : function() {
        incCount();
      },
      decCount: function() {
        decCount();
      },
      request: function(config) {
        incCount();

        return config;
      },
      requestError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      },
      response: function(response) {
        decCount();

        return response;
      },
      responseError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      }
    };
  }
})();
