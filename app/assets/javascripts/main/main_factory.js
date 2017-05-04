app
  .service('Flash', Flash)    // Сервис уведомлений пользователя (как об успешных операциях, так и об ошибках).
  .factory('Error', Error)    // Сервис обработки ошибок.
  .factory('Server', Server)  // Фабрика для работы с CRUD экшнами.

Flash.$inject   = ['$timeout'];
Error.$inject   = ['Flash'];
Server.$inject  = ['$resource'];

// =====================================================================================================================

/**
 * Сервис уведомления пользователей как об успешных операциях, так и об ошибочных.
 *
 * @class SVT.Flash
 */
function Flash($timeout) {
  this.$timeout = $timeout;

  this.flash = {
    notice: '',
    alert:  ''
  };
}

/**
 * Показать notice уведомление и скрыть его через 2 секунды.
 *
 * @param message - сообщение, которое необходимо вывести.
 */
Flash.prototype.notice = function (message) {
  var self = this;

  this.flash.alert  = null;
  this.flash.notice = message;

  this.$timeout(function () {
    self.flash.notice = null;
  }, 2000);
};

/**
 * Показать alert уведомление.
 *
 * @param message - сообщение, которое необходимо вывести.
 */
Flash.prototype.alert = function (message) {
  this.flash.notice = null;
  this.flash.alert  = message;
};

// =====================================================================================================================

/**
 * Сервис обработки ошибок, полученных с сервера.
 *
 * @class SVT.Error
 */
function Error(Flash) {
  return {
    /**
     * Обработать ответ сервера, содержащий ошибку и вывести сообщение об ошибке пользователю.
     *
     * @param response - объект, содержащий ответ сервера
     * @param status - статус ответа (необязательный параметр, используется, если не удается найти статус в
     * параметре "response")
     */
    response: function (response, status) {
      // Код ответа
      var code;
      // Расшифровка статуса ошибки.
      var descr;

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
          descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';

          if (response.data) {
            if (response.data.full_message)
              Flash.alert(response.data.full_message);
            else
              Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
          } else {
            if (response.data.full_message)
              Flash.alert(response.full_message);
            else
              Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
          }
          break;
        default:
          descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';
          Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
          break;
      }
    }
  }
}

// =====================================================================================================================

/**
 * Фабрика для работы с CRUD экшнами.
 *
 * @class SVT.Server
 */
function Server($resource) {
  return {
    /**
     * Ресурс модели рабочих мест
     */
    Workplace: $resource('/inventory/workplaces/:workplace_id.json', {}, { update: { method: 'PATCH' } }),
    /**
     * Ресурс модели отделов с количеством рабочих мест
     */
    WorkplaceCount: $resource('/inventory/workplace_counts/:workplace_count_id.json', {}, { update: { method: 'PATCH' } })
  }
}

// =====================================================================================================================