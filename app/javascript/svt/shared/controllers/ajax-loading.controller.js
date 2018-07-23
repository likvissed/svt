import { app } from '../../app/app';

(function() {
  app.controller('AjaxLoadingCtrl', AjaxLoadingCtrl);

  AjaxLoadingCtrl.$inject = ['$scope', 'myHttpInterceptor'];

  /**
   * Контроллер для управления индикатором выполнения ajax запросов.
   *
   * @class SVT.AjaxLoadingCtrl
   */
  function AjaxLoadingCtrl($scope, myHttpInterceptor) {
    this.requests = myHttpInterceptor.getRequestsCount; // Число запросов

    // Настройка ajax запросов, посланных с помощью jQuery (например, в datatables).
    $.ajaxSetup({
      beforeSend: () => myHttpInterceptor.incCount(),
      complete: () => {
        myHttpInterceptor.decCount();

        this.requests = myHttpInterceptor.getRequestsCount;

        $scope.$apply();
      }
    });
  }
})();
