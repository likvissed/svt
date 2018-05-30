(function() {
  'use strict';

  app
    .directive('ngWarehouseItemSupplyPopover', ngWarehouseItemSupplyPopover)
    .directive('ngWarehouseItemSupplyPopoverContent', ngWarehouseItemSupplyPopoverContent);

  ngWarehouseItemSupplyPopover.$inject = ['$compile'];
  ngWarehouseItemSupplyPopoverContent.$inject = ['$compile'];

  function ngWarehouseItemSupplyPopover($compile) {
    return {
      restrict: 'E',
      template: '<i class="fa fa-truck fa-fw pointer" uib-tooltip="Поставки" uib-popover-template="\'myPopoverTemplate.html\'" popover-title="Список поставок: {{item.item_type}}" popover-placement="right"></i>',
    }
  }

  function ngWarehouseItemSupplyPopoverContent($compile) {
    return {
      restrict: 'E',
      controller: 'WarehouseItemsCtrl as items',
      template: '\
        <div ng-show="$parent.item.supplies.length != 0">\
          <table class="table table-condensed">\
            <tr ng-repeat="supply in $parent.item.supplies">\
              <td class="col-fhd-1">\
                <i class="fa fa-eye fa-fw pointer" uib-tooltip="Просмотреть поставку" ng-click="items.showSupply(supply, $parent.item)"></i>\
              </td>\
              <td class="col-fhd-23">\
                {{supply.name}} от {{supply.date}}\
                <span ng-show="supply.supplyer">\
                  (Поставщик: {{supply.supplyer}})\
                </span>\
              </td>\
            </tr>\
          </table>\
        </div>\
        <div ng-show="$parent.item.supplies.length == 0">\
          <h5>Данные о поставках отсутствуют</h5>\
        </div>'
    }
  }
})();