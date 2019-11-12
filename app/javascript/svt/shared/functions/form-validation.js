/**
 * Содержит функции вывода ошибок валидации форм.
 *
 * @class SVT.DefaultDataTableCtrl
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
FormValidationController.prototype._setValidations = function(array, flag) {
  angular.forEach(array, (value, key) => {
    value.forEach((message) => {
      if (this.form[`${this._formName}[${key}]`]) {
        this.form[`${this._formName}[${key}]`].$setValidity(message, flag);
      }
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
  this.clearErrors();
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
  let message = [];

  angular.forEach(this.form[name].$error, function(value, key) {
    this.push(key);
  }, message);

  return message.join(', ');
};

export { FormValidationController }
