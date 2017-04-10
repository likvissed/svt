(function () {
  'use strict';

  app
    .directive('disableLink', disableLink)
    .directive('datatableWrapper', datatableWrapper)
    .directive('newRecord', newRecord);

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
            $compile(element.find('.new-record'))(scope);
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

})();

