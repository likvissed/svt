app
  .service('Flash', Flash)                          // Сервис уведомлений пользователя (как об успешных операциях,
  // так и об ошибках)
  .service('Error', Error)                          // Сервис обработки ошибок
  .factory('Server', Server)
  .factory('TableSettings', TableSettings);

Server.$inject        = ['$resource'];
TableSettings.$inject = [];

// =====================================================================================================================

/**
 * Сервис уведомления пользователей как об успешных операциях, так и об ошибочных.
 *
 * @class Inv.Flash
 */
function Flash($timeout) {
  var self = this;

  self.flash = {
    notice: '',
    alert:  ''
  };

  /**
   * Показать notice уведомление и скрыть его через 2 секунды.
   *
   * @methodOf Inv.Flash
   * @param message - сообщение, которое необходимо вывести
   */
  self.notice = function (message) {
    self.flash.alert  = null;
    self.flash.notice = message;

    $timeout(function () {
      self.flash.notice = null;
    }, 2000);
  };

  /**
   * Показать alert уведомление.
   *
   * @methodOf Inv.Flash
   * @param message - сообщение, которое необходимо вывести
   */
  self.alert = function (message) {
    self.flash.notice = null;
    self.flash.alert  = message;
  };
}

// =====================================================================================================================

/**
 * Сервис обработки ошибок, полученных с сервера.
 *
 * @class Inv.Error
 * @param Flash - описание {@link Inv.Flash}
 */
function Error(Flash) {
  var self = this;

  /**
   * Обработать ответ сервера, содержащий ошибку и вывести сообщение об ошибке пользователю.
   *
   * @methodOf Inv.Error
   * @param response - объект, содержащий ответ сервера
   * @param status - статус ответа (необязательный параметр, используется, если не удается найти статус в
   * параметре "response")
   */
  self.response = function (response, status) {
    var code; // код ответа

    code = (response && response.status) ? parseInt(response.status): parseInt(status);

    switch(code) {
      case 401:
        Flash.alert('Ваш сеанс закончился. Пожалуйста, войдите в систему снова.');
        break;
      case 403:
        Flash.alert('Доступ запрещен.');
        break;
      case 404:
        Flash.alert('Запись не найдена.');
        break;
      case 422:
        response.data ? Flash.alert(response.data.full_message) : Flash.alert(response.full_message);
        break;
      default:
        var descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';
        Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
        break;
    }
  };
}

// =====================================================================================================================

/**
 * Фабрика для работы с CRUD действиями
 *
 * @class Inv.Server
 * @param $resource
 */
function Server($resource) {
  return {
    /**
     * Ресурс модели рабочих мест
     *
     * @memberOf Inv.Server
     */
    Workplace: $resource('/workplaces/:workplace_id.json', {}, { update: { method: 'PATCH' } }),
    /**
     * Ресурс модели отделов с количеством рабочих мест
     *
     * @memberOf Inv.Server
     */
    CountWorkplace: $resource('/count_workplaces/:count_workplace_id.json', {}, { update: { method: 'PATCH' } })
  }
}

// =====================================================================================================================

/**
 * Фабрика для работы с таблицами.
 *
 * @class Inv.MainTable
 */
function TableSettings() {

  function classTable(tableName) {
    this._index = 0;
  }

  classTable.prototype.renderIndex = function () {

  };

  return classTable;
}