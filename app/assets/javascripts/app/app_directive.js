(function () {
  'use strict';

  app
    .directive('disableLink', disableLink)
    .directive('datatableWrapper', datatableWrapper)
    .directive('newRecord', newRecord)
    .directive('typeaheadOpenOnFocus', typeaheadOpenOnFocus);

  disableLink.$inject = [];
  datatableWrapper.$inject = ['$timeout', '$compile'];
  newRecord.$inject = [];
  typeaheadOpenOnFocus.$inject = ['$parse', '$timeout'];

// =====================================================================================================================

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
            $compile(element.find('.new-record'))(scope);

            $compile(element.find('.workplaces-division-filter'))(scope);
            $compile(element.find('.workplaces-status-filter'))(scope);
            $compile(element.find('.workplaces-type-filter'))(scope);

            $compile(element.find('.create-workplace-count-list'))(scope);

            $compile(element.find('.workplace-list-approve'))(scope);
            $compile(element.find('.workplace-list-division-filter'))(scope);
          }, 0, false);
        }

        compileElements();

        scope.$watch(
          function (scope) {
            // Для таблицы РМ
            if (scope.wpIndex) {
              return [
                scope.wpIndex.selectedDivisionFilter,
                scope.wpIndex.selectedStatusFilter,
                scope.wpIndex.selectedTypeFilter
              ];
            }

            if (scope.wpCount) {
              return [
                scope.wpCount.createWorkplaceCountList
              ];
            }

            // Для списка РМ
            if (scope.wpList) {
              return [
                scope.wpList.selectedDivisionFilter
              ];
            }
          },
          function () {
            compileElements();
          },
          true
        )
      }
    };
  }

  // Для таблицы DataTable добавить кнопку "Добавить", если у пользователя есть доступ
  // Необходимо добавить в атрибут id имя контроллера, на который отправится запрос
  function newRecord() {
    return {
      restrict: 'C',
      //template: '<button class="btn-sm btn btn-primary btn-block"
      // ng-click="contactPage.showContactModal()">Добавить</button>'
      templateUrl: function (element, attrs) {
        return '/link/new_record.json?ctrl_name=' + attrs.id;
      }
    }
  }

  // Автооткрытие поля 'select' (на самом деле это поле input) для выбора значения из списка.
  function typeaheadOpenOnFocus($parse, $timeout) {
    return {
      require: 'ngModel',
      link: function(scope, element, attrs) {
        element.on('click', function (event) {
          var
            ctrl = element.controller('ngModel'),
            prev = ctrl.$modelValue || '';

          if (prev) {
            ctrl.$setViewValue('');
            $timeout(function() {
              ctrl.$setViewValue(prev);
            });
          } else {
            ctrl.$setViewValue(' ');
          }
        })
      }
    }
  }
})();

