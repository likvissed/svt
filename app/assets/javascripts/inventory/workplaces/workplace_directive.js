app
  .directive('fileUpload', fileUpload)
  .directive('workplacesDivisionFilter', workplacesDivisionFilter);

fileUpload.$inject = [];
workplacesDivisionFilter.$inject = [];

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

// Фильтр по отделам
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
      '</ui-select>' + '</div>'
  }
}
