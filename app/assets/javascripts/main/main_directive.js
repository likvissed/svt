(function () {
  'use strict';

  app
    .directive('disableLink', disableLink)
    .directive('datatableWrapper', datatableWrapper);

  datatableWrapper.$inject = ['$timeout', '$compile'];

  // Отключить переход по ссылке
  function disableLink() {
    return {
      restrict: 'A',
      link: function (scope, element, attrs) {
        var checkLink = function (data) {
          if (data)
            element.on('click', function (event) {
              event.preventDefault();
            });
          else
            element.off().on('click', function() {
              return true;
            })
        };

        scope.$watch(attrs.disableLink, function (newValue, oldValue) {
          checkLink(newValue);
        });
      }
    }
  }

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

