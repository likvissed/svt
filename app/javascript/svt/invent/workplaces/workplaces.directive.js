import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .directive('fileUpload', fileUpload)
    .directive('workplaceListApprove', workplaceListApprove)
    .directive('workplaceListDivisionFilter', workplaceListDivisionFilter);

  function fileUpload(){
    return {
      link: function(scope, element, attrs) {
        element.on('change', function(event) {
          // Сохраняется сам файл, а также имя файла в массив данных
          scope.manually.setPcFile(event.target.files[0]);
        });
      }
    };
  }

  // Кнопки Подтвердить/Отменить
  function workplaceListApprove() {
    return {
      restrict: 'C',
      template:
      '<div class="btn-group btn-group-sm">' +
        '<button type="button" class="btn-success" ng-click="wpList.updateWp(\'confirm\')" ng-disabled="!wpList.flags.all && !wpList.flags.single">Подтвердить</button>' +
        '<button type="button" class="btn-danger" ng-click="wpList.updateWp(\'disapprove\')" ng-disabled="!wpList.flags.all && !wpList.flags.single">Отклонить</button>' +
      '</div>'
    }
  }

  // Фильтр РМ по отделам
  function workplaceListDivisionFilter() {
    return {
      restrict: 'C',
      template:
      '<div class="form-input-sm">' +
        '<ui-select ng-model="wpList.selectedDivisionFilter" on-select="wpList.changeFilter()" theme="bootstrap">' +
          '<ui-select-match>{{ $select.selected.division }}</ui-select-match>' +
          '<ui-select-choices repeat="obj in wpList.divisionFilters | filter: $select.search">' +
            '<div ng-bind-html="obj.division | highlight: $select.search">' +
          '</ui-select-choices>' +
        '</ui-select>' +
      '</div>'
    }
  }
})();
