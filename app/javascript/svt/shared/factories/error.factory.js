import { app } from '../../app/app';

(function() {
  app.factory('Error', Error);

  Error.$inject = ['Flash'];

  /**
   * Фабрика для обработки ошибок, полученных с сервера.
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
      response: function(response, status) {
        let
          // Код ответа
          code,
          // Расшифровка статуса ошибки.
          descr;

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
            let message = response.data ? response.data.full_message : response.full_message;

            if (message) {
              Flash.alert(message);
            } else {
              descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';
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
})();

