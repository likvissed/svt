(function () {
  'use strict';

  app
    .service('Flash', Flash) // Сервис уведомлений пользователя (как об успешных операциях, так и об ошибках).
    .factory('Error', Error) // Сервис обработки ошибок.
    .factory('Server', Server) // Фабрика для работы с CRUD экшнами.
    .factory('myHttpInterceptor', myHttpInterceptor) // Фабрика для настройки параметрв для индикатора выполнения
    .factory('Cookies', Cookies);

  Flash.$inject = ['$timeout'];
  Error.$inject = ['Flash'];
  Server.$inject = ['$resource'];
  myHttpInterceptor.$inject = ['$q'];
  Cookies.$inject = ['$cookies'];

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

    this.flash.alert = null;
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
    this.flash.alert = message;
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
        var
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
            var message = response.data ? response.data.full_message : response.full_message;

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
      Workplace: $resource('/inventory/workplaces/:workplace_id.json', {}, {
        update: {
          method: 'PUT',
          headers: { 'Content-Type': undefined },
          transformRequest: angular.identity
        },
        confirm: {
          method: 'PUT',
          url: '/inventory/workplaces/confirm'
        }
      }),
      /**
       * Ресурс модели отделов с количеством рабочих мест
       */
      WorkplaceCount: $resource('/inventory/workplace_counts/:workplace_count_id.json', {}, { update: { method: 'PUT' } })
    }
  }

// =====================================================================================================================

  /**
   * Фабрика для настройки параметрв для индикатора выполнения ajax запросов
   *
   * @class SVT.myHttpInterceptor
   */
  function myHttpInterceptor($q) {
    var self = this;

    self.requests = {
      count: 0
    };

    /**
     * Увеличить счетчик запросов.
     */
    function incCount() {
      self.requests.count ++;
    }

    /**
     * Уменьшить счетчик запросов.
     */
    function decCount() {
      self.requests.count --;
    }

    return {
      getRequestsCount: self.requests,
      incCount: function () {
        incCount();
      },
      decCount: function () {
        decCount();
      },
      request: function(config) {
        incCount();

        return config;
      },
      requestError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      },
      response: function(response) {
        decCount();

        return response;
      },
      responseError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      }
    };
  }

// =====================================================================================================================

  /**
   * Сервис для работы с cookies.
   *
   * @class SVT.Cookies
   */
  function Cookies($cookies) {
    var obj;

    /**
     * Инициализация cookies указанного объекта.
     *
     * @param name
     */
    function init(name) {
      switch (name) {
        case 'workplace':
          obj = {
            // Фильтр по отделам
            tableDivisionFilter: '0',
            // Фильтр по статусам
            tableStatusFilter: 'all',
            // Фильтр по типам
            tableTypeFilter: '0',
            // Фильтр списка РМ по отделам
            tableListDivisionFilter: '0'
          };
          break;
      }

      if (angular.isUndefined($cookies.getObject(name))) {
        // Установить начальные значения переменных куки
        $cookies.putObject(name, obj);
      } else {
        // Проверяем, существуют ли в cookies все ключи объекта obj
        angular.forEach(obj, function (value, key) {
          if (angular.isUndefined($cookies.getObject(name)[key])) {
            setCookie(name, key, value);
          }
        });

        // Получить актуальные значения переменных куки
        obj = $cookies.getObject(name);
      }
    }

    /**
     * Получить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     */
    function getCookie(name, key) {
      if (angular.isUndefined(key))
        return $cookies.getObject(name);

      return angular.isUndefined($cookies.getObject(name)) ? 'Cookies отсутсвуют' : $cookies.getObject(name)[key];
    }

    /**
     * Установить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     * @param value - устанавливаемое значение
     */
    function setCookie(name, key, value) {
      obj[key] = value;

      $cookies.putObject(name, obj);
    }

    return {
      /**
       * Страница /workplaces.
       */
      Workplace: {
        init: function () {
          init('workplace');
        },
        get: function (key) {
          return getCookie('workplace', key);
        },
        set: function (key, value) {
          setCookie('workplace', key, value);
        }
      }
    }
  }
})();
