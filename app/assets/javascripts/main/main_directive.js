(function () {
  'use strict';

  app
    .directive('datatableWrapper', datatableWrapper);

  datatableWrapper.$inject = ['$timeout', '$compile'];

// Скомпилировать представление таблиц DataTable
// Нужно для работы директивы newRecord, так как на момент добавления этой директивы DOM уже скомпилирован
  function datatableWrapper($timeout, $compile) {
    return {
      restrict: 'E',
      transclude: true,
      template: '<ng-transclude></ng-transclude>',
      link: function (scope, element, attrs) {
        function compileElements() {
          $timeout(function () {
          }, 0, false);
        }

        compileElements();

        scope.$watch(
          function (scope) {
          },
          function () {
            compileElements();
          },
          true
        )
      }
    };
  }

})();

