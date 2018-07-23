import { app } from '../../app/app';

(function() {
  app.controller('FlashMessageCtrl', FlashMessageCtrl);

  FlashMessageCtrl.$inject = ['$scope', '$attrs', 'Flash'];

  /**
   * Контроллер для управления уведомлениями. После того, как страница отрендерится, контроллер запустит Flash
   * уведомления, полученные от сервера.
   *
   * @class SVT.FlashMessageCtrl
   */
  function FlashMessageCtrl($scope, $attrs, Flash) {
    $scope.flash = Flash.flash;

    if ($attrs.notice) { Flash.notice($attrs.notice); }
    if ($attrs.alert) { Flash.alert($attrs.alert); }

    /**
     * Убрать alert уведомление.
     */
    $scope.disableAlert = function() {
      Flash.alert(null);
    };
  }
})();
