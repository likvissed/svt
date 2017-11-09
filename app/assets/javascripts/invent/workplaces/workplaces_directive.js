(function () {
  'use strict';

  app
    .directive('fileUpload', fileUpload)
    .directive('workplacesInventNumFilter', workplacesInventNumFilter)
    .directive('workplacesIdFilter', workplacesIdFilter)
    .directive('workplacesDivisionFilter', workplacesDivisionFilter)
    .directive('workplacesStatusFilter', workplacesStatusFilter)
    .directive('workplacesTypeFilter', workplacesTypeFilter)
    .directive('workplaceListApprove', workplaceListApprove)
    .directive('workplaceListDivisionFilter', workplaceListDivisionFilter);

  function fileUpload(){
    return {
      link: function (scope, element, attrs) {
        element.on('change', function (event) {
          // Сохраняется сам файл, а также имя файла в массив данных
          scope.manually.setPcFile(event.target.files[0]);
        });
      }
    };
  }

  // Фильтр РМ по инвентарному номеру
  function workplacesInventNumFilter() {
    return {
      restrict: 'C',
      template:
      '<input type="text" class="form-control input-sm" placeholder="Инвентарный №" ' +
      'ng-model-options="{ debounce: 1500 }" ng-model="wpIndex.selectedInventNumFilter" ng-change="wpIndex.changeFilter()">'
    }
  }

  // Фильтр РМ по ID
  function workplacesIdFilter() {
    return {
      restrict: 'C',
      template:
      '<input type="text" class="form-control input-sm" placeholder="ID" ng-model="wpIndex.selectedIdFilter" ' +
      'ng-model-options="{ debounce: 500 }" ng-change="wpIndex.changeFilter()">'
    }
  }

  // Фильтр РМ по отделам
  function workplacesDivisionFilter() {
    return {
      restrict: 'C',
      template:
      '<div class="form-input-sm">' +
        '<ui-select ng-model="wpIndex.selectedDivisionFilter" on-select="wpIndex.changeFilter()" theme="bootstrap">' +
          '<ui-select-match>{{ $select.selected.division }}</ui-select-match>' +
          '<ui-select-choices repeat="obj in wpIndex.divisionFilters | filter: $select.search">' +
            '<div ng-bind-html="obj.division | highlight: $select.search">' +
          '</ui-select-choices>' +
        '</ui-select>' +
      '</div>'
    }
  }

  // Фильтр РМ по статусам
  function workplacesStatusFilter() {
    return {
      restrict: 'C',
      template:
      '<select class="form-control input-sm" ng-model="wpIndex.selectedStatusFilter" ng-options="status as ' +
      'translated for (status, translated) in wpIndex.statusFilters" ng-change="wpIndex.changeFilter()"></select>'
    }
  }

  // Фильтр РМ по типам
  function workplacesTypeFilter() {
    return {
      restrict: 'C',
      template:
      '<select class="form-control input-sm" ng-model="wpIndex.selectedTypeFilter" ng-options="type as ' +
      'type.short_description for type in wpIndex.typeFilters" ng-change="wpIndex.changeFilter()"></select>'
    }
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
