app
  .controller('FlashMessageCtrl', FlashMessageCtrl)                   // Связывает переменные уведомлений с фабрикой
  .controller('DefaultDataTableCtrl', DefaultDataTableCtrl)           // Основные настройки таблицы angular-datatable
  .controller('FormValidationController', FormValidationController);  // Функции вывода ошибок валидаций форм

DefaultDataTableCtrl.$inject = ['DTDefaultOptions'];

// =====================================================================================================================

/**
 * Контроллер для управления уведомлениями. После того, как страница отрендерится, контроллер запустит Flash
 * уведомления, полученные от сервера.
 *
 * @class DataCenter.FlashMessageCtrl
 * @param $scope
 * @param $attrs
 * @param Flash - описание: {@link DataCenter.Flash}
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
  $scope.disableAlert = function () {
    Flash.alert(null);
  };
}

// =====================================================================================================================

/**
 * Основные настройки таблиц angular-datatable.
 *
 * @class Inv.DefaultDataTableCtrl
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
 * Содержит функции вывода ошибок валидации форм.
 *
 * @class Inv.DefaultDataTableCtrl
 */
function FormValidationController() {
  this._errors = null;
  this._formName = '';
}

/**
 * Установить валидаторы на поля формы. В случае ошибок валидации пользователю будет предоставлено сообщение об
 * ошибке.
 *
 * @param array - объект, содержащий ошибки
 * @param flag - флаг, устанавливаемый в объект form (false - валидация не пройдена, true - пройдена)
 */
FormValidationController.prototype._setValidations = function (array, flag) {
  var self = this;

  $.each(array, function (key, value) {
    $.each(value, function (index, message) {
      if (key != 'base')
        self.form[self._formName + '[' + key + ']'].$setValidity(message, flag);
    });
  });
};

/**
 * Установить имя формы.
 *
 * @param name - имя формы
 */
FormValidationController.prototype.setFormName = function (name) {
  this._formName = name;
};

/**
 * Действия в случае ошибки создания/изменения данных формы.
 *
 * @param response - ответ с сервера
 */
FormValidationController.prototype.errorResponse = function (response) {
  this._errors = response.data.object;
  this._setValidations(this._errors, false);
};

/**
 * Очистить форму от ошибок.
 */
FormValidationController.prototype.clearErrors = function () {
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
FormValidationController.prototype.errorClass = function (name) {
  return (this.form[name].$invalid) ? 'has-error': ''
};

/**
 * Добавить сообщение о соответствующей ошибке к элементу формы, содержащей ошибочные данные.
 *
 * @param name - имя поля в DOM.
 */
FormValidationController.prototype.errorMessage = function (name) {
  var message = [];

  $.each(this.form[name].$error, function (key, value) {
    message.push(key);
  });

  return message.join(', ');
};

// =====================================================================================================================