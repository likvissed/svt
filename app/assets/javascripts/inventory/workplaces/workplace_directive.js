app
  .directive('fileUpload', fileUpload)
  .directive('workplacesDivisionFilter', workplacesDivisionFilter)
  .directive('workplacesStatusFilter', workplacesStatusFilter)
  .directive('workplacesTypeFilter', workplacesTypeFilter);

fileUpload.$inject = [];
workplacesDivisionFilter.$inject = [];
workplacesStatusFilter.$inject = [];
workplacesTypeFilter.$inject = [];

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