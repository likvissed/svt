import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .directive('ngExecInOrderTable', ngExecInOrderTable);

  ngExecInOrderTable.$inject = ['$compile'];

  function ngExecInOrderTable($compile) {
    return function(scope, element, attrs) {
      // Исключили работу директивы в расходных и во всех исполненных ордерах
      if (scope.$parent.exec.order.operation != 'in' || scope.$parent.exec.order.status == 'done') { return true; }

      element.removeAttr('ng-exec-in-order-table');
      var mes;
      if (scope.op.unreg == true) {
        mes = 'Хост разрегистрирован'
      } else if (scope.op.unreg == false) {
        mes = 'Хост не разрегистрирован'
      }
      element.attr('ng-class', "{ success: op.unreg == true, danger: op.unreg == false }").attr('uib-tooltip', mes).attr('tooltip-append-to-body', 'true');
      $compile(element)(scope);
    }
  }
})();
