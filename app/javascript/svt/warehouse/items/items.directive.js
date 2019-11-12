import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .directive('ngWarehouseItemSupplyPopover', ngWarehouseItemSupplyPopover)
    .directive('ngWarehouseItemSupplyPopoverContent', ngWarehouseItemSupplyPopoverContent);

  ngWarehouseItemSupplyPopover.$inject = ['$compile'];
  ngWarehouseItemSupplyPopoverContent.$inject = ['$compile'];

  function ngWarehouseItemSupplyPopover() {
    return {
      restrict: 'E',
      template: '<i class="fa fa-truck fa-fw pointer" uib-tooltip="Поставки" uib-popover-template="\'myPopoverTemplate.html\'" popover-title="Список поставок: {{item.item_type}}" popover-placement="right"></i>'
    }
  }

  function ngWarehouseItemSupplyPopoverContent() {

    return {
      restrict  : 'E',
      controller: 'WarehouseItemsCtrl as items',
      template  : '\n'+
        '<div ng-show="$parent.item.supplies.length != 0"> \n' +
          '<table class="table table-condensed">\n' +
            '<tr ng-repeat="supply in $parent.item.supplies">\n' +
              '<td class="col-fhd-1">\n' +
                '<i class="fa fa-eye fa-fw pointer" uib-tooltip="Просмотреть поставку" ng-click="items.showSupply(supply, $parent.item)"></i>\n' +
              '</td>\n' +
              '<td class="col-fhd-23">\n' +
                '{{supply.name}} от {{supply.date}}\n' +
                '<span ng-show="supply.supplyer">\n' +
                  '(Поставщик: {{supply.supplyer}})\n' +
                '</span>\n' +
              '</td>\n' +
            '</tr>\n' +
          '</table>\n' +
        '</div>\n' +
        '<div ng-show="$parent.item.supplies.length == 0">\n' +
          '<h5>Данные о поставках отсутствуют</h5>\n' +
        '</div>'
    }
  }
})();
