import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .directive('ngCompileItemRows', ngCompileItemRows);

  ngCompileItemRows.$inject = ['$compile'];

  function ngCompileItemRows($compile) {
    return function(scope, element) {
      /**
       * Директива должна работать только для ИБП
       * if (scope.item.type.name != 'ups') { return true; }
       */
      element.removeAttr('ng-compile-item-rows');

      if (scope.$parent.table.colorizeUps(scope.item)) {
        let msg = `Батареи менялись более ${scope.item['need_battery_replacement?'].years} лет назад`;
        element.attr('ng-class', 'table.colorizeUps(item)').attr('uib-tooltip', msg)
               .attr('tooltip-append-to-body', 'true');
      }

      element.find('#editItem').attr('ng-click', 'table.editItem(item)');
      element.find('#destroyItem').attr('ng-click', 'table.destroyItem(item)');
      $compile(element)(scope);
    }
  }
})();
