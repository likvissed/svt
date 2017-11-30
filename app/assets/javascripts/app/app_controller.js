(function() {
  'use strict';

  app
    .controller('FlashMessageCtrl', FlashMessageCtrl) // Связывает переменные уведомлений с фабрикой
    .controller('DefaultDataTableCtrl', DefaultDataTableCtrl) // Основные настройки таблицы angular-datatable
    .controller('AjaxLoadingCtrl', AjaxLoadingCtrl); // Связывает переменные индикатора загрузки с фабрикой

  FlashMessageCtrl.$inject = ['$scope', '$attrs', 'Flash'];
  DefaultDataTableCtrl.$inject = ['DTDefaultOptions'];
  AjaxLoadingCtrl.$inject = ['$scope', 'myHttpInterceptor'];

// =====================================================================================================================

  /**
   * Контроллер для управления уведомлениями. После того, как страница отрендерится, контроллер запустит Flash
   * уведомления, полученные от сервера.
   *
   * @class SVT.FlashMessageCtrl
   */
  function FlashMessageCtrl($scope, $attrs, Flash) {
    $scope.flash = Flash.flash;

    if ($attrs.notice)
      Flash.notice($attrs.notice);

    if ($attrs.alert)
      Flash.alert($attrs.alert);

    /**
     * Убрать alert уведомление.
     */
    $scope.disableAlert = function() {
      Flash.alert(null);
    };
  }

// =====================================================================================================================

  /**
   * Основные настройки таблиц angular-datatable.
   *
   * @class SVT.DefaultDataTableCtrl
   */
  function DefaultDataTableCtrl(DTDefaultOptions) {
    DTDefaultOptions
      .setLanguage({
        emptyTable: 'Данные отсутствуют',
        paginate: { //Нумерация страниц
          first:    'Перв.',
          last:     'Посл.',
          previous: 'Пред.',
          next:     'След.'
        },
        search:             '',
        searchPlaceholder:  'Поиск',
        zeroRecords:        'Данные отсутсвуют',
        lengthMenu:         'Показано _MENU_ записей',
        processing:         'Выполнение...',
        loadingRecords:     'Загрузка данных с сервера...',
        info:               'Записи с _START_ по _END_ из _TOTAL_',
        infoFiltered:       '(выборка из _MAX_ записей)',
        infoEmpty:          '0 записей'
      })
      .setDisplayLength(25)
      .setDOM('<"row"<"col-fhd-24"f>>t<"row"<"col-fhd-24"p>>');
  }

// =====================================================================================================================

  /**
   * Контроллер для управления индикатором выполнения ajax запросов.
   *
   * @class SVT.AjaxLoadingCtrl
   */
  function AjaxLoadingCtrl($scope, myHttpInterceptor) {
    var self = this;

    self.requests = myHttpInterceptor.getRequestsCount; // Число запросов

    // Настройка ajax запросов, посланных с помощью jQuery (например, в datatables).
    $.ajaxSetup({
      beforeSend: function() {
        myHttpInterceptor.incCount();
      },
      complete: function() {
        myHttpInterceptor.decCount();

        self.requests = myHttpInterceptor.getRequestsCount;

        $scope.$apply();
      }
    });
  }
})();

// =====================================================================================================================

/**
 * Содержит функции вывода ошибок валидации форм.
 *
 * @class SVT.DefaultDataTableCtrl
 */
function FormValidationController() {
  this._errors    = null;
  this._formName  = '';
}

/**
 * Установить валидаторы на поля формы. В случае ошибок валидации пользователю будет предоставлено сообщение об
 * ошибке.
 *
 * @param array - объект, содержащий ошибки
 * @param flag - флаг, устанавливаемый в объект form (false - валидация не пройдена, true - пройдена)
 */
FormValidationController.prototype._setValidations = function(array, flag) {
  var self = this;

  angular.forEach(array, function(value, key) {
    value.forEach(function(message) {
      if (self.form[self._formName + '[' + key + ']'])
        self.form[self._formName + '[' + key + ']'].$setValidity(message, flag);
    });
  });
};

/**
 * Установить имя формы.
 *
 * @param name - имя формы
 */
FormValidationController.prototype.setFormName = function(name) {
  this._formName = name;
};

/**
 * Действия в случае ошибки создания/изменения данных формы.
 *
 * @param response - ответ с сервера
 */
FormValidationController.prototype.errorResponse = function(response) {
  this._errors = response.data.object;
  this._setValidations(this._errors, false);
};

/**
 * Очистить форму от ошибок.
 */
FormValidationController.prototype.clearErrors = function() {
  if (this._errors) {
    this._setValidations(this._errors, true);
    this._errors = null;
  }
};

/**
 * Добавить класс "has-error" к элементу форму, содержащей ошибочные данные.
 *
 * @param name - имя поля в DOM.
 */
FormValidationController.prototype.errorClass = function(name) {
  return (this.form[name].$invalid) ? 'has-error': ''
};

/**
 * Добавить сообщение о соответствующей ошибке к элементу формы, содержащей ошибочные данные.
 *
 * @param name - имя поля в DOM.
 */
FormValidationController.prototype.errorMessage = function(name) {
  var message = [];

  angular.forEach(this.form[name].$error, function(value, key) {
    this.push(key);
  }, message);

  return message.join(', ');
};